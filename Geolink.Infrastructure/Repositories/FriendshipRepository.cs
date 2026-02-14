using Geolink.Application.Interfaces;
using Geolink.Domain.Entities;
using Geolink.Domain.Enums;
using Geolink.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace Geolink.Infrastructure.Repositories;

public class FriendshipRepository : Repository<Friendship>, IFriendshipRepository
{
    public FriendshipRepository(GeolinkDbContext context) : base(context)
    {
    }

    public async Task<Friendship?> GetFriendshipAsync(Guid userId1, Guid userId2, CancellationToken cancellationToken = default)
    {
        return await _dbSet
            .Include(f => f.Requester)
            .Include(f => f.Addressee)
            .FirstOrDefaultAsync(f => 
                (f.RequesterId == userId1 && f.AddresseeId == userId2) ||
                (f.RequesterId == userId2 && f.AddresseeId == userId1), 
                cancellationToken);
    }

    public async Task<IEnumerable<Friendship>> GetUserFriendsAsync(Guid userId, FriendshipStatus status = FriendshipStatus.Accepted, CancellationToken cancellationToken = default)
    {
        return await _dbSet
            .Include(f => f.Requester)
            .Include(f => f.Addressee)
            .Where(f => (f.RequesterId == userId || f.AddresseeId == userId) && f.Status == status)
            .ToListAsync(cancellationToken);
    }

    public async Task<IEnumerable<Friendship>> GetPendingRequestsAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        return await _dbSet
            .Include(f => f.Requester)
            .Include(f => f.Addressee)
            .Where(f => (f.RequesterId == userId || f.AddresseeId == userId) && f.Status == FriendshipStatus.Pending)
            .ToListAsync(cancellationToken);
    }

    public async Task<bool> AreFriendsAsync(Guid userId1, Guid userId2, CancellationToken cancellationToken = default)
    {
        return await _dbSet
            .AnyAsync(f => 
                ((f.RequesterId == userId1 && f.AddresseeId == userId2) ||
                 (f.RequesterId == userId2 && f.AddresseeId == userId1)) &&
                f.Status == FriendshipStatus.Accepted, 
                cancellationToken);
    }
}
