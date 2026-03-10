using Geolink.Application.DTOs.Location;
using Geolink.Application.Interfaces;
using Geolink.Domain.Enums;

namespace Geolink.Infrastructure.Services;

public class FriendsMapService : IFriendsMapService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILocationCacheService _locationCache;

    public FriendsMapService(IUnitOfWork unitOfWork, ILocationCacheService locationCache)
    {
        _unitOfWork = unitOfWork;
        _locationCache = locationCache;
    }

    public async Task<IEnumerable<FriendLocationDto>> GetFriendsWithLocationsAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var friendships = await _unitOfWork.Friendships.GetUserFriendsAsync(
            userId, 
            FriendshipStatus.Approved,
            cancellationToken);

        if (!friendships.Any())
            return Enumerable.Empty<FriendLocationDto>();

        var friendIds = friendships
            .Select(f => f.RequesterId == userId ? f.AddresseeId : f.RequesterId)
            .Distinct()
            .ToList();

        // Получить их локации из Redis
        var locations = await _locationCache.GetLocationsAsync(friendIds, cancellationToken);

        // Получить информацию о друзьях из БД
        var friends = await _unitOfWork.Users.GetAllAsync(cancellationToken);
        var friendsMap = friends
            .Where(u => friendIds.Contains(u.Id))
            .ToDictionary(u => u.Id);

        // Объединить: для каждой локации найти username
        var result = locations
            .Where(loc => friendsMap.ContainsKey(loc.UserId))
            .Select(loc => new FriendLocationDto(
                loc.UserId,
                friendsMap[loc.UserId].UserName ?? "",
                loc.Latitude,
                loc.Longitude,
                loc.UpdatedAtUtc
            ))
            .ToList();

        return result;
    }
}
