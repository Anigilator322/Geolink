using Geolink.Application.Common;
using Geolink.Application.UseCaseContracts;

namespace Geolink.Application.Interfaces;

public interface IUpdateUserLocationUseCase
{
    Task<Result<UpdateLocationResponse>> ExecuteAsync(
        UpdateLocationRequest request,
        CancellationToken cancellationToken = default);
}
