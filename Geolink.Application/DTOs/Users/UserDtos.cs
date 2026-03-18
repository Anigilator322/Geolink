namespace Geolink.Application.DTOs.Users;

public record UserDto(
    Guid Id,
    string Email,
    string Username,
    string? AvatarUrl,
    string? Bio,
    bool Approved,
    DateTime CreatedAt
);

public record UpdateUserRequest(
    string? Bio,
    string? AvatarUrl
);

public record UpdateProfileRequest(
    string? Username,
    string? Bio
);

public record UserSearchResult(
    Guid Id,
    string Username,
    string? AvatarUrl
);
