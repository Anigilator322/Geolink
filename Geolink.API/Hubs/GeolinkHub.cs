using System.Security.Claims;
using Geolink.Application.DTOs.Location;
using Geolink.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace Geolink.API.Hubs;

[Authorize]
public class GeolinkHub : Hub
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILocationCacheService? _locationCache;
    private static readonly Dictionary<Guid, string> _userConnections = new();

    public GeolinkHub(IUnitOfWork unitOfWork, ILocationCacheService? locationCache = null)
    {
        _unitOfWork = unitOfWork;
        _locationCache = locationCache;
    }

    public override async Task OnConnectedAsync()
    {
        var userId = GetUserId();
        if (userId.HasValue)
        {
            _userConnections[userId.Value] = Context.ConnectionId;
            
            // Notify friends that user is online
            var friends = await _unitOfWork.Friendships.GetUserFriendsAsync(userId.Value);
            foreach (var friendship in friends)
            {
                var friendId = friendship.RequesterId == userId ? friendship.AddresseeId : friendship.RequesterId;
                if (_userConnections.TryGetValue(friendId, out var connectionId))
                {
                    await Clients.Client(connectionId).SendAsync("FriendOnline", userId.Value);
                }
            }
        }
        
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        var userId = GetUserId();
        if (userId.HasValue)
        {
            _userConnections.Remove(userId.Value);
            
            // Notify friends that user is offline
            var friends = await _unitOfWork.Friendships.GetUserFriendsAsync(userId.Value);
            foreach (var friendship in friends)
            {
                var friendId = friendship.RequesterId == userId ? friendship.AddresseeId : friendship.RequesterId;
                if (_userConnections.TryGetValue(friendId, out var connectionId))
                {
                    await Clients.Client(connectionId).SendAsync("FriendOffline", userId.Value);
                }
            }
        }
        
        await base.OnDisconnectedAsync(exception);
    }

    public async Task UpdateLocation(UpdateLocationRequest request)
    {
        var userId = GetUserId();
        if (!userId.HasValue) return;

        // Update location in cache (Redis)
        if (_locationCache != null)
        {
            await _locationCache.SetLocationAsync(userId.Value, request.Latitude, request.Longitude);
        }

        // Update location in database
        var location = await _unitOfWork.UserLocations.GetByUserIdAsync(userId.Value);
        if (location != null)
        {
            location.Latitude = request.Latitude;
            location.Longitude = request.Longitude;
            location.Accuracy = request.Accuracy;
            location.Altitude = request.Altitude;
            location.Speed = request.Speed;
            location.Heading = request.Heading;
            location.UpdatedAt = DateTime.UtcNow;
        }
        else
        {
            await _unitOfWork.UserLocations.AddAsync(new Domain.Entities.UserLocation
            {
                UserId = userId.Value,
                Latitude = request.Latitude,
                Longitude = request.Longitude,
                Accuracy = request.Accuracy,
                Altitude = request.Altitude,
                Speed = request.Speed,
                Heading = request.Heading
            });
        }
        
        await _unitOfWork.SaveChangesAsync();

        // Broadcast to friends
        var friends = await _unitOfWork.Friendships.GetUserFriendsAsync(userId.Value);
        var user = await _unitOfWork.Users.GetByIdAsync(userId.Value);
        
        foreach (var friendship in friends)
        {
            var friendId = friendship.RequesterId == userId ? friendship.AddresseeId : friendship.RequesterId;
            if (_userConnections.TryGetValue(friendId, out var connectionId))
            {
                await Clients.Client(connectionId).SendAsync("FriendLocationUpdated", new LocationDto(
                    userId.Value,
                    user?.Username ?? "",
                    user?.DisplayName,
                    user?.AvatarUrl,
                    request.Latitude,
                    request.Longitude,
                    request.Accuracy,
                    DateTime.UtcNow
                ));
            }
        }
    }

    public async Task SendFriendRequest(Guid addresseeId)
    {
        var userId = GetUserId();
        if (!userId.HasValue) return;

        if (_userConnections.TryGetValue(addresseeId, out var connectionId))
        {
            var user = await _unitOfWork.Users.GetByIdAsync(userId.Value);
            await Clients.Client(connectionId).SendAsync("FriendRequestReceived", new
            {
                UserId = userId.Value,
                Username = user?.Username,
                DisplayName = user?.DisplayName,
                AvatarUrl = user?.AvatarUrl
            });
        }
    }

    public async Task NotifyEventInvitation(Guid eventId, Guid inviteeId)
    {
        var userId = GetUserId();
        if (!userId.HasValue) return;

        if (_userConnections.TryGetValue(inviteeId, out var connectionId))
        {
            var eventEntity = await _unitOfWork.Events.GetByIdAsync(eventId);
            await Clients.Client(connectionId).SendAsync("EventInvitation", new
            {
                EventId = eventId,
                Title = eventEntity?.Title,
                InviterId = userId.Value
            });
        }
    }

    private Guid? GetUserId()
    {
        var userIdClaim = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value 
                       ?? Context.User?.FindFirst("sub")?.Value;
        
        return Guid.TryParse(userIdClaim, out var userId) ? userId : null;
    }
}
