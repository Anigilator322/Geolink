using Geolink.Application.DTOs.Location;

namespace Geolink.Application.Interfaces;

public interface ILocationCacheService
{
    /// <summary>
    /// Сохранить текущую геолокацию пользователя в Redis
    /// </summary>
    Task SetLocationAsync(
        Guid userId, 
        double latitude, 
        double longitude, 
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Получить геолокацию пользователя из Redis.
    /// Возвращает null если локация не найдена.
    /// </summary>
    Task<LocationCacheDto?> GetLocationAsync(
        Guid userId, 
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Получить геолокации нескольких пользователей из Redis
    /// </summary>
    Task<IEnumerable<LocationCacheDto>> GetLocationsAsync(
        IEnumerable<Guid> userIds,
        CancellationToken cancellationToken = default);
}
