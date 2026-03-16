using Geolink.Application.DTOs.Location;

namespace Geolink.API.Realtime;

public interface IFriendLocationBroadcastService
{
    Task BroadcastFriendLocationUpdatedAsync(
        FriendLocationDto location,
        CancellationToken cancellationToken = default);
}
