using System.Globalization;
using Geolink.Application.DTOs.Location;
using Geolink.Application.Interfaces;
using StackExchange.Redis;

namespace Geolink.Infrastructure.Services;

public class LocationCacheService : ILocationCacheService
{
    private readonly IConnectionMultiplexer _redis;
    private readonly IDatabase _db;
    private const string KeyPrefix = "location:";

    public LocationCacheService(IConnectionMultiplexer redis)
    {
        _redis = redis;
        _db = redis.GetDatabase();
    }

    public async Task SetLocationAsync(
        Guid userId, 
        double latitude, 
        double longitude, 
        CancellationToken cancellationToken = default)
    {
        var key = $"{KeyPrefix}{userId}";
        var updatedAtUtc = DateTime.UtcNow;
        var value = $"{latitude.ToString(CultureInfo.InvariantCulture)},{longitude.ToString(CultureInfo.InvariantCulture)},{updatedAtUtc.Ticks}";
        await _db.StringSetAsync(key, value, TimeSpan.FromMinutes(5));
    }

    public async Task<LocationCacheDto?> GetLocationAsync(
        Guid userId, 
        CancellationToken cancellationToken = default)
    {
        var key = $"{KeyPrefix}{userId}";
        var value = await _db.StringGetAsync(key);
        
        if (value.IsNullOrEmpty)
            return null;

        var parts = value.ToString().Split(',');
        if (parts.Length < 3 || 
            !double.TryParse(parts[0], CultureInfo.InvariantCulture, out var latitude) || 
            !double.TryParse(parts[1], CultureInfo.InvariantCulture, out var longitude) ||
            !long.TryParse(parts[2], CultureInfo.InvariantCulture, out var ticks))
            return null;

        return new LocationCacheDto(
            userId,
            latitude,
            longitude,
            new DateTime(ticks, DateTimeKind.Utc)
        );
    }

    public async Task<IEnumerable<LocationCacheDto>> GetLocationsAsync(
        IEnumerable<Guid> userIds,
        CancellationToken cancellationToken = default)
    {
        var result = new List<LocationCacheDto>();
        var keys = userIds.Select(id => (RedisKey)$"{KeyPrefix}{id}").ToArray();
        
        var values = await _db.StringGetAsync(keys);
        
        var userIdList = userIds.ToList();
        for (int i = 0; i < values.Length; i++)
        {
            if (!values[i].IsNullOrEmpty)
            {
                var parts = values[i].ToString().Split(',');
                if (parts.Length >= 3 && 
                    double.TryParse(parts[0], CultureInfo.InvariantCulture, out var latitude) && 
                    double.TryParse(parts[1], CultureInfo.InvariantCulture, out var longitude) &&
                    long.TryParse(parts[2], CultureInfo.InvariantCulture, out var ticks))
                {
                    result.Add(new LocationCacheDto(
                        userIdList[i],
                        latitude,
                        longitude,
                        new DateTime(ticks, DateTimeKind.Utc)
                    ));
                }
            }
        }

        return result;
    }
}
