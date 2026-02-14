using Geolink.Domain.Common;

namespace Geolink.Domain.Entities;

public class UserLocation : BaseEntity
{
    public Guid UserId { get; set; }
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public double? Accuracy { get; set; }
    public double? Altitude { get; set; }
    public double? Speed { get; set; }
    public double? Heading { get; set; }
    public bool IsSharing { get; set; } = true;

    // Navigation property
    public User User { get; set; } = null!;
}
