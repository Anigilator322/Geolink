using Geolink.Domain.Common;
using Geolink.Domain.Enums;

namespace Geolink.Domain.Entities;

public class EventSettings : BaseEntity
{
    public Guid EventId { get; set; }
    public DateTime StartsAt { get; set; }
    public DateTime? EndsAt { get; set; }
    public bool IsPublic { get; set; } = true;
    public int? MaxParticipants { get; set; }
    public string? PreviewUrl { get; set; }
    public string? Description { get; set; }
    public bool RequireRegistration { get; set; } = false;
    public string? Address { get; set; }
    public EventStatus Status { get; set; } = EventStatus.Scheduled;

    // Navigation property
    public Event Event { get; set; } = null!;
}
