namespace Geolink.Application.DTOs.Auth;

public record RegisterRequest(
    string Email,
    string Username,
    string Password,
    string? DisplayName = null
);

public record LoginRequest(
    string Email,
    string Password
);

public record RefreshTokenRequest(
    string RefreshToken
);

public record AuthResponse(
    Guid UserId,
    string Email,
    string Username,
    string? DisplayName,
    string AccessToken,
    string RefreshToken,
    DateTime ExpiresAt
);
