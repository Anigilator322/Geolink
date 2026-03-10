namespace Geolink.Application.DTOs.Location;

public record LocationDto(
    Guid UserId,
    string Username,
    string? AvatarUrl,
    double Latitude,
    double Longitude,
    double? Accuracy,
    DateTime UpdatedAt
);

public record UpdateLocationRequest(
    double Latitude,
    double Longitude,
    double? Accuracy = null,
    double? Altitude = null,
    double? Speed = null,
    double? Heading = null
);

public record LocationSharingRequest(
    bool IsSharing
);
