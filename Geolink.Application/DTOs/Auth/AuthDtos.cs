namespace Geolink.Application.DTOs.Auth;

/// <summary>Шаг 1 входа — запрос OTP на данный электронный адрес.</summary>
public record SendCodeRequest(string Email);

/// <summary>Шаг 2 входа — проверить OTP, полученный на электронный адрес.</summary>
public record VerifyCodeRequest(string Email, string Code);

/// <summary>Выдана когда OTP действителен. Содержит пару JWT.</summary>
public record AuthResponse(
    Guid UserId,
    string Email,
    string Username,
    string AccessToken,
    string RefreshToken,
    DateTime ExpiresAt
);

public record RefreshTokenRequest(string RefreshToken);
