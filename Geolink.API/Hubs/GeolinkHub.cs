using Geolink.API.Common;
using Geolink.API.Realtime;
using Geolink.Application.DTOs.Location;
using Geolink.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace Geolink.API.Hubs;

[Authorize]
public class GeolinkHub : Hub
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IUserConnectionRegistry _connectionRegistry;
    private readonly IHubActionAuthorizationService _hubAuthorization;
    private readonly IUpdateUserLocationUseCase _updateUserLocation;
    private readonly IFriendLocationBroadcastService _friendLocationBroadcast;
    private readonly ILogger<GeolinkHub> _logger;

    public GeolinkHub(
        IUnitOfWork unitOfWork,
        IUserConnectionRegistry connectionRegistry,
        IHubActionAuthorizationService hubAuthorization,
        IUpdateUserLocationUseCase updateUserLocation,
        IFriendLocationBroadcastService friendLocationBroadcast,
        ILogger<GeolinkHub> logger)
    {
        _unitOfWork = unitOfWork;
        _connectionRegistry = connectionRegistry;
        _hubAuthorization = hubAuthorization;
        _updateUserLocation = updateUserLocation;
        _friendLocationBroadcast = friendLocationBroadcast;
        _logger = logger;
    }

    public override async Task OnConnectedAsync()
    {
        if (!Context.User.TryGetUserId(out var userId))
        {
            _logger.LogWarning("Connection {ConnectionId} has no valid user claim.", Context.ConnectionId);
            await base.OnConnectedAsync();
            return;
        }

        var becameOnline = _connectionRegistry.AddConnection(userId, Context.ConnectionId);
        var connectionCount = _connectionRegistry.GetConnections(userId).Count;

        _logger.LogInformation(
            "User {UserId} connected with {ConnectionId}. Active connections: {ConnectionCount}",
            userId,
            Context.ConnectionId,
            connectionCount);

        if (becameOnline)
            await NotifyFriendPresenceAsync(userId, "FriendOnline", Context.ConnectionAborted);

        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        if (!Context.User.TryGetUserId(out var userId))
        {
            await base.OnDisconnectedAsync(exception);
            return;
        }

        var becameOffline = _connectionRegistry.RemoveConnection(userId, Context.ConnectionId);
        var connectionCount = _connectionRegistry.GetConnections(userId).Count;

        _logger.LogInformation(
            "User {UserId} disconnected with {ConnectionId}. Active connections: {ConnectionCount}",
            userId,
            Context.ConnectionId,
            connectionCount);

        if (becameOffline)
            await NotifyFriendPresenceAsync(userId, "FriendOffline", CancellationToken.None);

        await base.OnDisconnectedAsync(exception);
    }

    public async Task UpdateLocation(UpdateLocationRequest request)
    {
        if (!Context.User.TryGetUserId(out var userId))
            throw new HubException("Unauthorized.");

        var result = await _updateUserLocation.ExecuteAsync(new Application.UseCaseContracts.UpdateLocationRequest(
            userId, 
            request.Latitude, 
            request.Longitude), Context.ConnectionAborted);
        if (!result.IsSuccess)
        {
            _logger.LogWarning(
                "Location update denied for {UserId}. Reason: {Reason}",
                userId,
                result.Error);

            throw new HubException(result.Error ?? "Location update failed.");
        }
        var friendLocation = new FriendLocationDto(result.Value.UserId,
            result.Value.Username,
            result.Value.Latitude,
            result.Value.Longitude,
            result.Value.UpdatedAtUtc);
        await _friendLocationBroadcast.BroadcastFriendLocationUpdatedAsync(friendLocation, Context.ConnectionAborted);

        _logger.LogDebug(
            "Location updated for user {UserId}: ({Latitude}, {Longitude})",
            userId,
            request.Latitude,
            request.Longitude);
    }

    public async Task SendFriendRequest(Guid addresseeId)
    {
        if (!Context.User.TryGetUserId(out var senderId))
            throw new HubException("Unauthorized.");

        var authResult = await _hubAuthorization.AuthorizeFriendRequestAsync(
            senderId,
            addresseeId,
            Context.ConnectionAborted);

        if (!authResult.IsSuccess)
        {
            _logger.LogWarning(
                "Denied SendFriendRequest from {SenderId} to {AddresseeId}. Reason: {Reason}",
                senderId,
                addresseeId,
                authResult.Error);

            throw new HubException(authResult.Error ?? "Forbidden.");
        }

        var connections = _connectionRegistry.GetConnections(addresseeId);
        if (connections.Count == 0)
            return;

        var sender = await _unitOfWork.Users.GetByIdAsync(senderId, Context.ConnectionAborted);

        await Clients.Clients(connections).SendAsync("FriendRequestReceived", new
        {
            UserId = senderId,
            Username = sender?.UserName,
            AvatarUrl = sender?.AvatarUrl
        }, Context.ConnectionAborted);
    }

    public async Task NotifyEventInvitation(Guid eventId, Guid inviteeId)
    {
        if (!Context.User.TryGetUserId(out var inviterId))
            throw new HubException("Unauthorized.");

        var authResult = await _hubAuthorization.AuthorizeEventInvitationAsync(
            inviterId,
            eventId,
            inviteeId,
            Context.ConnectionAborted);

        if (!authResult.IsSuccess)
        {
            _logger.LogWarning(
                "Denied NotifyEventInvitation from {InviterId} to {InviteeId} for event {EventId}. Reason: {Reason}",
                inviterId,
                inviteeId,
                eventId,
                authResult.Error);

            throw new HubException(authResult.Error ?? "Forbidden.");
        }

        var connections = _connectionRegistry.GetConnections(inviteeId);
        if (connections.Count == 0)
            return;

        var eventEntity = await _unitOfWork.Events.GetByIdAsync(eventId, Context.ConnectionAborted);

        await Clients.Clients(connections).SendAsync("EventInvitation", new
        {
            EventId = eventId,
            Title = eventEntity?.Title,
            InviterId = inviterId
        }, Context.ConnectionAborted);
    }

    private async Task NotifyFriendPresenceAsync(
        Guid userId,
        string eventName,
        CancellationToken cancellationToken)
    {
        var friendships = await _unitOfWork.Friendships.GetUserFriendsAsync(userId, cancellationToken: cancellationToken);

        foreach (var friendship in friendships)
        {
            var friendId = friendship.RequesterId == userId
                ? friendship.AddresseeId
                : friendship.RequesterId;

            var connections = _connectionRegistry.GetConnections(friendId);
            if (connections.Count == 0)
                continue;

            await Clients.Clients(connections).SendAsync(eventName, userId, cancellationToken);
        }
    }
}