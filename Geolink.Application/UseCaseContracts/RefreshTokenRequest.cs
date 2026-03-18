namespace Geolink.Application.UseCaseContracts;

public record RefreshTokenRequest(
    string RefreshToken,
    string? IpAddress = null
);

public record RefreshTokenResponse(
    Guid UserId,
    string Email,
    string Username,
    string AccessToken,
    string RefreshToken,
    DateTime ExpiresAt
);
