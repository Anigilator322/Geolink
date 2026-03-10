namespace Geolink.Application.DTOs.Auth;

/// <summary>Step 1 of login — request an OTP to the given email.</summary>
public record SendCodeRequest(string Email);

/// <summary>Step 2 of login — verify the OTP received by email.</summary>
public record VerifyCodeRequest(string Email, string Code);

/// <summary>Issued when the OTP is valid. Contains the JWT pair.</summary>
public record AuthResponse(
    Guid UserId,
    string Email,
    string Username,
    string AccessToken,
    string RefreshToken,
    DateTime ExpiresAt
);

public record RefreshTokenRequest(string RefreshToken);
