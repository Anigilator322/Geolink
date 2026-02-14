namespace Geolink.Application.Interfaces;

public interface ILocationCacheService
{
    Task SetLocationAsync(Guid userId, double latitude, double longitude, TimeSpan? expiry = null);
    Task<(double Latitude, double Longitude)?> GetLocationAsync(Guid userId);
    Task<Dictionary<Guid, (double Latitude, double Longitude)>> GetLocationsAsync(IEnumerable<Guid> userIds);
    Task RemoveLocationAsync(Guid userId);
}
