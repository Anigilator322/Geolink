using Geolink.Application.Common;
using Geolink.Application.DTOs.Location;

namespace Geolink.Application.Interfaces;

public interface IUpdateUserLocationUseCase
{
    Task<Result<FriendLocationDto>> ExecuteAsync(
        Guid userId,
        UpdateLocationRequest request,
        CancellationToken cancellationToken = default);
}
