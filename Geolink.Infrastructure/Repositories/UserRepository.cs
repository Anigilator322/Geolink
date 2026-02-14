using Geolink.Application.Interfaces;
using Geolink.Domain.Entities;
using Geolink.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace Geolink.Infrastructure.Repositories;

public class UserRepository : Repository<User>, IUserRepository
{
    public UserRepository(GeolinkDbContext context) : base(context)
    {
    }

    public async Task<User?> GetByEmailAsync(string email, CancellationToken cancellationToken = default)
    {
        return await _dbSet
            .FirstOrDefaultAsync(u => u.Email.ToLower() == email.ToLower(), cancellationToken);
    }

    public async Task<User?> GetByUsernameAsync(string username, CancellationToken cancellationToken = default)
    {
        return await _dbSet
            .FirstOrDefaultAsync(u => u.Username.ToLower() == username.ToLower(), cancellationToken);
    }

    public async Task<IEnumerable<User>> SearchUsersAsync(string query, int limit = 20, CancellationToken cancellationToken = default)
    {
        var lowerQuery = query.ToLower();
        return await _dbSet
            .Where(u => u.Username.ToLower().Contains(lowerQuery) || 
                       (u.DisplayName != null && u.DisplayName.ToLower().Contains(lowerQuery)))
            .Take(limit)
            .ToListAsync(cancellationToken);
    }

    public async Task<bool> ExistsAsync(string email, string username, CancellationToken cancellationToken = default)
    {
        return await _dbSet
            .AnyAsync(u => u.Email.ToLower() == email.ToLower() || 
                          u.Username.ToLower() == username.ToLower(), cancellationToken);
    }
}
