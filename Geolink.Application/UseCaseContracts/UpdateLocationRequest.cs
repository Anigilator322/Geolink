namespace Geolink.Application.UseCaseContracts
{
    public record UpdateLocationRequest(
    Guid UserId,
    double Latitude,
    double Longitude
);

    public record UpdateLocationResponse(
        Guid UserId,
        string Username,
        double Latitude,
        double Longitude,
        DateTime UpdatedAtUtc
    );
}
