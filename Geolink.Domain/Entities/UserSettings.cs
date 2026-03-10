using Geolink.Domain.Common;

namespace Geolink.Domain.Entities;

public class UserSettings : BaseEntity
{
    public Guid UserId { get; set; }
    public bool ShareLocation { get; set; } = true;
    public int LocationRefreshTimingSeconds { get; set; } = 30;

    // Navigation properties
    public User User { get; set; } = null!;
    public ICollection<User> HideFrom { get; set; } = new List<User>();
}
