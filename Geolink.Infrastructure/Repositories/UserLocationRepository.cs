using Geolink.Application.Interfaces;
using Geolink.Domain.Entities;
using Geolink.Domain.Enums;
using Geolink.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace Geolink.Infrastructure.Repositories;

public class UserLocationRepository : Repository<UserLocation>, IUserLocationRepository
{
    public UserLocationRepository(GeolinkDbContext context) : base(context)
    {
    }

    public async Task<UserLocation?> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        return await _dbSet
            .Include(l => l.User)
            .FirstOrDefaultAsync(l => l.UserId == userId, cancellationToken);
    }

    public async Task<IEnumerable<UserLocation>> GetFriendsLocationsAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var friendIds = await _context.Friendships
            .Where(f => (f.RequesterId == userId || f.AddresseeId == userId) && f.Status == FriendshipStatus.Accepted)
            .Select(f => f.RequesterId == userId ? f.AddresseeId : f.RequesterId)
            .ToListAsync(cancellationToken);

        return await _dbSet
            .Include(l => l.User)
            .Where(l => friendIds.Contains(l.UserId) && l.IsSharing)
            .ToListAsync(cancellationToken);
    }

    public async Task UpsertAsync(UserLocation location, CancellationToken cancellationToken = default)
    {
        var existing = await _dbSet.FirstOrDefaultAsync(l => l.UserId == location.UserId, cancellationToken);
        
        if (existing == null)
        {
            await _dbSet.AddAsync(location, cancellationToken);
        }
        else
        {
            existing.Latitude = location.Latitude;
            existing.Longitude = location.Longitude;
            existing.Accuracy = location.Accuracy;
            existing.Altitude = location.Altitude;
            existing.Speed = location.Speed;
            existing.Heading = location.Heading;
            existing.UpdatedAt = DateTime.UtcNow;
        }
    }
}
