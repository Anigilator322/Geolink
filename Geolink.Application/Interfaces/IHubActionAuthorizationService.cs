using Geolink.Application.Common;

namespace Geolink.Application.Interfaces;

public interface IHubActionAuthorizationService
{
    Task<Result> AuthorizeFriendRequestAsync(
        Guid senderId,
        Guid addresseeId,
        CancellationToken cancellationToken = default);

    Task<Result> AuthorizeEventInvitationAsync(
        Guid inviterId,
        Guid eventId,
        Guid inviteeId,
        CancellationToken cancellationToken = default);
}
