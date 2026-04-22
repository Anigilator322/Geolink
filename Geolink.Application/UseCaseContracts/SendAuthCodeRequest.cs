namespace Geolink.Application.UseCaseContracts
{
    public record SendAuthCodeRequest(string Email);
    public record SendAuthCodeResponse(
        Guid UserId,
        string Email,
        string Username,
        string AccessToken,
        string RefreshToken,
        DateTime ExpiresAt
    );
}
