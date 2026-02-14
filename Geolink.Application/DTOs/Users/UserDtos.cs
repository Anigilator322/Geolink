namespace Geolink.Application.DTOs.Users;

public record UserDto(
    Guid Id,
    string Email,
    string Username,
    string? DisplayName,
    string? AvatarUrl,
    string? Bio,
    DateTime? LastSeenAt,
    DateTime CreatedAt
);

public record UpdateUserRequest(
    string? DisplayName,
    string? Bio,
    string? AvatarUrl
);

public record UserSearchResult(
    Guid Id,
    string Username,
    string? DisplayName,
    string? AvatarUrl
);
