using Geolink.Application.Common;
using Geolink.Application.Interfaces;
using Geolink.Domain.Enums;

namespace Geolink.Application.Services;

public class HubActionAuthorizationService : IHubActionAuthorizationService
{
    private readonly IUnitOfWork _unitOfWork;

    public HubActionAuthorizationService(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task<Result> AuthorizeFriendRequestAsync(
        Guid senderId,
        Guid addresseeId,
        CancellationToken cancellationToken = default)
    {
        if (senderId == Guid.Empty || addresseeId == Guid.Empty)
            return Result.Unauthorized("Invalid user context.");

        if (senderId == addresseeId)
            return Result.Failure("You cannot send a friend request to yourself.");

        var sender = await _unitOfWork.Users.GetByIdAsync(senderId, cancellationToken);
        if (sender is null)
            return Result.Unauthorized("Sender user was not found.");

        var addressee = await _unitOfWork.Users.GetByIdAsync(addresseeId, cancellationToken);
        if (addressee is null)
            return Result.NotFound("Addressee user was not found.");

        var friendship = await _unitOfWork.Friendships.GetFriendshipAsync(senderId, addresseeId, cancellationToken);
        if (friendship is null)
            return Result.Success();

        return friendship.Status switch
        {
            FriendshipStatus.Pending => Result.Failure("Friend request already exists.", 409),
            FriendshipStatus.Approved => Result.Failure("Users are already friends.", 409),
            FriendshipStatus.Declined => Result.Success(),
            FriendshipStatus.Removed => Result.Success(),
            _ => Result.Failure("Friend request cannot be sent.")
        };
    }

    public async Task<Result> AuthorizeEventInvitationAsync(
        Guid inviterId,
        Guid eventId,
        Guid inviteeId,
        CancellationToken cancellationToken = default)
    {
        if (inviterId == Guid.Empty || inviteeId == Guid.Empty)
            return Result.Unauthorized("Invalid user context.");

        if (eventId == Guid.Empty)
            return Result.Failure("Event id is required.");

        if (inviterId == inviteeId)
            return Result.Failure("You cannot invite yourself.");

        var invitee = await _unitOfWork.Users.GetByIdAsync(inviteeId, cancellationToken);
        if (invitee is null)
            return Result.NotFound("Invitee user was not found.");

        var eventEntity = await _unitOfWork.Events.GetWithParticipantsAsync(eventId, cancellationToken);
        if (eventEntity is null || eventEntity.EventSettings is null)
            return Result.NotFound("Event was not found.");

        if (eventEntity.EventSettings.Status is EventStatus.Cancelled or EventStatus.Completed)
            return Result.Failure("Event is not available for invitations.", 409);

        var inviterParticipant = eventEntity.Participants
            .FirstOrDefault(p => p.UserId == inviterId);

        var canInvite = eventEntity.CreatorId == inviterId ||
                        inviterParticipant?.Status == ParticipantStatus.Accepted;
        if (!canInvite)
            return Result.Forbidden("Inviter has no rights to invite users to this event.");

        if (!eventEntity.EventSettings.IsPublic && eventEntity.CreatorId != inviterId)
            return Result.Forbidden("Only event creator can invite users to private events.");

        var areFriends = await _unitOfWork.Friendships.AreFriendsAsync(inviterId, inviteeId, cancellationToken);
        if (!areFriends)
            return Result.Forbidden("Invitee is not eligible for this invitation.");

        var inviteeParticipant = eventEntity.Participants.FirstOrDefault(p => p.UserId == inviteeId);
        if (inviteeParticipant is not null && inviteeParticipant.Status != ParticipantStatus.Declined)
            return Result.Failure("Invitee is already in this event.", 409);

        if (eventEntity.EventSettings.MaxParticipants.HasValue)
        {
            var acceptedCount = eventEntity.Participants.Count(p => p.Status == ParticipantStatus.Accepted);
            if (acceptedCount >= eventEntity.EventSettings.MaxParticipants.Value)
                return Result.Failure("Event has reached max participants.", 409);
        }

        return Result.Success();
    }
}
