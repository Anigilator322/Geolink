using Geolink.Domain.Entities;

namespace Geolink.Application.Interfaces;

public interface IUserLocationRepository : IRepository<UserLocation>
{
    Task<UserLocation?> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default);
    Task<IEnumerable<UserLocation>> GetFriendsLocationsAsync(Guid userId, CancellationToken cancellationToken = default);
    Task UpsertAsync(UserLocation location, CancellationToken cancellationToken = default);
}
