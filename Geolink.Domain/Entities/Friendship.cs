using Geolink.Domain.Common;
using Geolink.Domain.Enums;

namespace Geolink.Domain.Entities;

public class Friendship : BaseEntity
{
    public Guid RequesterId { get; set; }
    public Guid AddresseeId { get; set; }
    public FriendshipStatus Status { get; set; } = FriendshipStatus.Pending;
    public DateTime? AcceptedAt { get; set; }

    // Navigation properties
    public User Requester { get; set; } = null!;
    public User Addressee { get; set; } = null!;
}
