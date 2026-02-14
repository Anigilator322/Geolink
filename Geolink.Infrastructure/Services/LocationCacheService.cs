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

    public async Task SetLocationAsync(Guid userId, double latitude, double longitude, TimeSpan? expiry = null)
    {
        var key = $"{KeyPrefix}{userId}";
        var value = $"{latitude},{longitude},{DateTime.UtcNow:O}";
        await _db.StringSetAsync(key, value, expiry ?? TimeSpan.FromMinutes(5));
    }

    public async Task<(double Latitude, double Longitude)?> GetLocationAsync(Guid userId)
    {
        var key = $"{KeyPrefix}{userId}";
        var value = await _db.StringGetAsync(key);
        
        if (value.IsNullOrEmpty)
            return null;

        var parts = value.ToString().Split(',');
        if (parts.Length < 2)
            return null;

        return (double.Parse(parts[0]), double.Parse(parts[1]));
    }

    public async Task<Dictionary<Guid, (double Latitude, double Longitude)>> GetLocationsAsync(IEnumerable<Guid> userIds)
    {
        var result = new Dictionary<Guid, (double Latitude, double Longitude)>();
        var keys = userIds.Select(id => (RedisKey)$"{KeyPrefix}{id}").ToArray();
        
        var values = await _db.StringGetAsync(keys);
        
        var userIdList = userIds.ToList();
        for (int i = 0; i < values.Length; i++)
        {
            if (!values[i].IsNullOrEmpty)
            {
                var parts = values[i].ToString().Split(',');
                if (parts.Length >= 2)
                {
                    result[userIdList[i]] = (double.Parse(parts[0]), double.Parse(parts[1]));
                }
            }
        }

        return result;
    }

    public async Task RemoveLocationAsync(Guid userId)
    {
        var key = $"{KeyPrefix}{userId}";
        await _db.KeyDeleteAsync(key);
    }
}
