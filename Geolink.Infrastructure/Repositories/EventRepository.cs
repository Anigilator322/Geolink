using Geolink.Application.Interfaces;
using Geolink.Domain.Entities;
using Geolink.Domain.Enums;
using Geolink.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace Geolink.Infrastructure.Repositories;

public class EventRepository : Repository<Event>, IEventRepository
{
    public EventRepository(GeolinkDbContext context) : base(context)
    {
    }

    public async Task<IEnumerable<Event>> GetNearbyEventsAsync(double latitude, double longitude, double radiusKm, int limit = 50, CancellationToken cancellationToken = default)
    {
        // Simple distance calculation using Haversine formula approximation
        // For more accurate results, consider using PostGIS in production
        var latDelta = radiusKm / 111.0; // 1 degree latitude ≈ 111 km
        var lonDelta = radiusKm / (111.0 * Math.Cos(latitude * Math.PI / 180));

        return await _dbSet
            .Include(e => e.Creator)
            .Include(e => e.Participants)
            .Where(e => e.Status == EventStatus.Scheduled || e.Status == EventStatus.Active)
            .Where(e => e.StartsAt > DateTime.UtcNow.AddHours(-1))
            .Where(e => e.Latitude >= latitude - latDelta && e.Latitude <= latitude + latDelta)
            .Where(e => e.Longitude >= longitude - lonDelta && e.Longitude <= longitude + lonDelta)
            .OrderBy(e => e.StartsAt)
            .Take(limit)
            .ToListAsync(cancellationToken);
    }

    public async Task<IEnumerable<Event>> GetUserEventsAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        return await _dbSet
            .Include(e => e.Creator)
            .Include(e => e.Participants)
            .Where(e => e.CreatorId == userId || e.Participants.Any(p => p.UserId == userId))
            .OrderByDescending(e => e.StartsAt)
            .ToListAsync(cancellationToken);
    }

    public async Task<IEnumerable<Event>> GetUpcomingEventsAsync(int limit = 20, CancellationToken cancellationToken = default)
    {
        return await _dbSet
            .Include(e => e.Creator)
            .Include(e => e.Participants)
            .Where(e => e.Status == EventStatus.Scheduled && e.StartsAt > DateTime.UtcNow)
            .OrderBy(e => e.StartsAt)
            .Take(limit)
            .ToListAsync(cancellationToken);
    }

    public async Task<Event?> GetWithParticipantsAsync(Guid eventId, CancellationToken cancellationToken = default)
    {
        return await _dbSet
            .Include(e => e.Creator)
            .Include(e => e.Participants)
                .ThenInclude(p => p.User)
            .FirstOrDefaultAsync(e => e.Id == eventId, cancellationToken);
    }
}
