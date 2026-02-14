using Geolink.Domain.Common;
using Geolink.Domain.Enums;

namespace Geolink.Domain.Entities;

public class EventParticipant : BaseEntity
{
    public Guid EventId { get; set; }
    public Guid UserId { get; set; }
    public ParticipantStatus Status { get; set; } = ParticipantStatus.Pending;
    public DateTime? RespondedAt { get; set; }

    // Navigation properties
    public Event Event { get; set; } = null!;
    public User User { get; set; } = null!;
}
