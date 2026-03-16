namespace Geolink.Application.UseCaseContracts
{
    public record VerifyCodeRequest(
        string Email,
        string Code,
        string? IpAddress = null
    );

    public record VerifyCodeResponse(
        Guid UserId,
        string Email,
        string Username,
        string AccessToken,
        string RefreshToken,
        DateTime ExpiresAt
    );
}
