using Geolink.Domain.Entities;

namespace Geolink.Application.Interfaces;

public interface IEventRepository : IRepository<Event>
{
    Task<IEnumerable<Event>> GetNearbyEventsAsync(double latitude, double longitude, double radiusKm, int limit = 50, CancellationToken cancellationToken = default);
    Task<IEnumerable<Event>> GetUserEventsAsync(Guid userId, CancellationToken cancellationToken = default);
    Task<IEnumerable<Event>> GetUpcomingEventsAsync(int limit = 20, CancellationToken cancellationToken = default);
    Task<Event?> GetWithParticipantsAsync(Guid eventId, CancellationToken cancellationToken = default);
}
