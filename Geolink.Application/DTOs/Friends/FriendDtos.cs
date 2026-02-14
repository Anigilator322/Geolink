using Geolink.Domain.Enums;

namespace Geolink.Application.DTOs.Friends;

public record FriendDto(
    Guid UserId,
    string Username,
    string? DisplayName,
    string? AvatarUrl,
    DateTime? LastSeenAt,
    FriendshipStatus Status,
    DateTime FriendsSince
);

public record FriendRequestDto(
    Guid FriendshipId,
    Guid UserId,
    string Username,
    string? DisplayName,
    string? AvatarUrl,
    DateTime RequestedAt,
    bool IsIncoming
);

public record SendFriendRequestRequest(
    Guid AddresseeId
);

public record RespondToFriendRequestRequest(
    bool Accept
);
