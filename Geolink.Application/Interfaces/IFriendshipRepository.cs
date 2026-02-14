using Geolink.Domain.Entities;
using Geolink.Domain.Enums;

namespace Geolink.Application.Interfaces;

public interface IFriendshipRepository : IRepository<Friendship>
{
    Task<Friendship?> GetFriendshipAsync(Guid userId1, Guid userId2, CancellationToken cancellationToken = default);
    Task<IEnumerable<Friendship>> GetUserFriendsAsync(Guid userId, FriendshipStatus status = FriendshipStatus.Accepted, CancellationToken cancellationToken = default);
    Task<IEnumerable<Friendship>> GetPendingRequestsAsync(Guid userId, CancellationToken cancellationToken = default);
    Task<bool> AreFriendsAsync(Guid userId1, Guid userId2, CancellationToken cancellationToken = default);
}
