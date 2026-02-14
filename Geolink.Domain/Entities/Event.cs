using Geolink.Domain.Common;
using Geolink.Domain.Enums;

namespace Geolink.Domain.Entities;

public class Event : BaseEntity
{
    public Guid CreatorId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public string? Address { get; set; }
    public DateTime StartsAt { get; set; }
    public DateTime? EndsAt { get; set; }
    public int? MaxParticipants { get; set; }
    public bool IsPublic { get; set; } = true;
    public EventStatus Status { get; set; } = EventStatus.Scheduled;
    public string? ImageUrl { get; set; }

    // Navigation properties
    public User Creator { get; set; } = null!;
    public ICollection<EventParticipant> Participants { get; set; } = new List<EventParticipant>();
}
