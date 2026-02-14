using Geolink.Domain.Entities;

namespace Geolink.Application.Interfaces;

public interface IUserRepository : IRepository<User>
{
    Task<User?> GetByEmailAsync(string email, CancellationToken cancellationToken = default);
    Task<User?> GetByUsernameAsync(string username, CancellationToken cancellationToken = default);
    Task<IEnumerable<User>> SearchUsersAsync(string query, int limit = 20, CancellationToken cancellationToken = default);
    Task<bool> ExistsAsync(string email, string username, CancellationToken cancellationToken = default);
}
