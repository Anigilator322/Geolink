using Geolink.Application.DTOs.Location;

namespace Geolink.Application.Interfaces;

public interface IFriendsMapService
{
    /// <summary>
    /// Получить список друзей пользователя с их актуальными геолокациями из Redis.
    /// Возвращает только друзей, у которых есть актуальная локация.
    /// </summary>
    Task<IEnumerable<FriendLocationDto>> GetFriendsWithLocationsAsync(
        Guid userId,
        CancellationToken cancellationToken = default);
}
