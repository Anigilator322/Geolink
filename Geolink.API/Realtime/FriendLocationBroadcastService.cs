using Geolink.API.Hubs;
using Geolink.Application.DTOs.Location;
using Geolink.Application.Interfaces;
using Microsoft.AspNetCore.SignalR;

namespace Geolink.API.Realtime;

public class FriendLocationBroadcastService : IFriendLocationBroadcastService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IUserConnectionRegistry _connectionRegistry;
    private readonly IHubContext<GeolinkHub> _hubContext;
    private readonly ILogger<FriendLocationBroadcastService> _logger;

    public FriendLocationBroadcastService(
        IUnitOfWork unitOfWork,
        IUserConnectionRegistry connectionRegistry,
        IHubContext<GeolinkHub> hubContext,
        ILogger<FriendLocationBroadcastService> logger)
    {
        _unitOfWork = unitOfWork;
        _connectionRegistry = connectionRegistry;
        _hubContext = hubContext;
        _logger = logger;
    }

    public async Task BroadcastFriendLocationUpdatedAsync(
        FriendLocationDto location,
        CancellationToken cancellationToken = default)
    {
        var friendships = await _unitOfWork.Friendships.GetUserFriendsAsync(
            location.UserId,
            cancellationToken: cancellationToken);

        foreach (var friendship in friendships)
        {
            var friendId = friendship.RequesterId == location.UserId
                ? friendship.AddresseeId
                : friendship.RequesterId;

            var connections = _connectionRegistry.GetConnections(friendId);
            if (connections.Count == 0)
                continue;

            await _hubContext.Clients.Clients(connections)
                .SendAsync("FriendLocationUpdated", location, cancellationToken);
        }

        _logger.LogDebug(
            "Broadcasted FriendLocationUpdated for {UserId} at ({Latitude}, {Longitude})",
            location.UserId,
            location.Latitude,
            location.Longitude);
    }
}
