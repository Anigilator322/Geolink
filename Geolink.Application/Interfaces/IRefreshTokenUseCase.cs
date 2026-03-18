using Geolink.Application.Common;
using Geolink.Application.UseCaseContracts;

namespace Geolink.Application.Interfaces;

public interface IRefreshTokenUseCase
{
    Task<Result<RefreshTokenResponse>> ExecuteAsync(
        RefreshTokenRequest request,
        CancellationToken ct);
}
