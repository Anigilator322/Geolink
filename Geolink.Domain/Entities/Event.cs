using Geolink.Domain.Common;

namespace Geolink.Domain.Entities;

public class Event : BaseEntity
{
    public Guid CreatorId { get; set; }
    public string Title { get; set; } = string.Empty;
    public double Latitude { get; set; }
    public double Longitude { get; set; }

    // Navigation properties
    public User Creator { get; set; } = null!;
    public EventSettings EventSettings { get; set; } = null!;
    public ICollection<EventParticipant> Participants { get; set; } = new List<EventParticipant>();
}
