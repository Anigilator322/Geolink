namespace Geolink.Application.DTOs.Location;

public record UpdateLocationRequest(
    double Latitude,
    double Longitude
);

public record LocationCacheDto(
    Guid UserId,
    double Latitude,
    double Longitude,
    DateTime UpdatedAtUtc
);

public record FriendLocationDto(
    Guid UserId,
    string Username,
    double Latitude,
    double Longitude,
    DateTime UpdatedAtUtc
);
