using Geolink.Domain.Enums;

namespace Geolink.Application.DTOs.Events;

public record EventDto(
    Guid Id,
    Guid CreatorId,
    string CreatorUsername,
    string Title,
    string? Description,
    double Latitude,
    double Longitude,
    string? Address,
    DateTime StartsAt,
    DateTime? EndsAt,
    int? MaxParticipants,
    int CurrentParticipants,
    bool IsPublic,
    bool RequireRegistration,
    EventStatus Status,
    string? PreviewUrl,
    DateTime CreatedAt
);

public record CreateEventRequest(
    string Title,
    string? Description,
    double Latitude,
    double Longitude,
    string? Address,
    DateTime StartsAt,
    DateTime? EndsAt,
    int? MaxParticipants,
    bool IsPublic = true,
    bool RequireRegistration = false,
    string? PreviewUrl = null
);

public record UpdateEventRequest(
    string? Title,
    string? Description,
    double? Latitude,
    double? Longitude,
    string? Address,
    DateTime? StartsAt,
    DateTime? EndsAt,
    int? MaxParticipants,
    bool? IsPublic,
    bool? RequireRegistration,
    string? PreviewUrl
);

public record EventParticipantDto(
    Guid UserId,
    string Username,
    string? AvatarUrl,
    ParticipantStatus Status,
    DateTime? RespondedAt
);

public record JoinEventRequest(
    ParticipantStatus Status = ParticipantStatus.Accepted
);

public record NearbyEventsRequest(
    double Latitude,
    double Longitude,
    double RadiusKm = 10,
    int Limit = 50
);
