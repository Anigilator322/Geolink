namespace Geolink.Application.UseCaseContracts
{
    public record SendAuthCodeRequest(string Email);
    public record SendAuthCodeResponse(string Email);
}
