using Microsoft.AspNetCore.Identity;

namespace Geolink.Domain.Entities;

/// <summary>
/// Application user. Email is the primary identifier; login is done via OTP sent to Email.
/// </summary>
public class User : IdentityUser<Guid>
{
    // IdentityUser already provides: Id, Email, NormalizedEmail, UserName, NormalizedUserName,
    // SecurityStamp, ConcurrencyStamp, EmailConfirmed, LockoutEnd, AccessFailedCount, etc.

    public string? AvatarUrl { get; set; }
    public string? Bio { get; set; }

    /// <summary>Account is approved by admin or after first successful login.</summary>
    public bool Approved { get; set; } = false;

    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    // Navigation properties
    public UserLocation? CurrentLocation { get; set; }
    public UserSettings? Settings { get; set; }
    public ICollection<Friendship> SentFriendRequests { get; set; } = new List<Friendship>();
    public ICollection<Friendship> ReceivedFriendRequests { get; set; } = new List<Friendship>();
    public ICollection<Event> CreatedEvents { get; set; } = new List<Event>();
    public ICollection<EventParticipant> EventParticipations { get; set; } = new List<EventParticipant>();
    public ICollection<RefreshToken> RefreshTokens { get; set; } = new List<RefreshToken>();
}
