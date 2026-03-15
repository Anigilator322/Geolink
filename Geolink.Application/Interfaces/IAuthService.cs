using Geolink.Application.Common;
using Geolink.Application.DTOs.Auth;

namespace Geolink.Application.Interfaces;

public interface IAuthService
{
    Task<Result<bool>> SendCodeAsync(string email, CancellationToken cancellationToken = default);

    Task<Result<AuthResponse>> VerifyCodeAsync(string email, string code, string? ipAddress = null, CancellationToken cancellationToken = default);
}