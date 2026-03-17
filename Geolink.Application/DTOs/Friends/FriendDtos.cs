using Geolink.Domain.Enums;

namespace Geolink.Application.DTOs.Friends;

public record FriendDto(
    Guid UserId,
    string Username,
    string? AvatarUrl,
    FriendshipStatus Status,
    DateTime FriendsSince
);

public record FriendRequestDto(
    string AddresseeUsername
);

public record IncominFriendshipDto(
    Guid Id,
    Guid IssuerId,
    string IssuerUsername,
    FriendshipStatus Status
);

public record SendFriendRequestRequest(
    Guid AddresseeId
);

public record RespondToFriendRequestRequest(
    bool Accept
);
