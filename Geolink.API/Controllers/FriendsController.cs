using Geolink.API.Common;
using Geolink.Application.DTOs.Friends;
using Geolink.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Geolink.API.Controllers
{
    [ApiController]
    [Route("api/friends")]
    public class FriendsController : ControllerBase
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly IAddFriendUseCase _addFriendUseCase;

        public FriendsController(IUnitOfWork unitOfWork, IAddFriendUseCase addFriendUseCase)
        {
            _unitOfWork = unitOfWork;
            _addFriendUseCase = addFriendUseCase;
        }


        [HttpPost()]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> GetUserFriends(CancellationToken cancellationToken)
        {
            if (!User.TryGetUserId(out var userId))
                return Unauthorized();
            var friendships = await _unitOfWork.Friendships.GetUserFriendsAsync(userId, Domain.Enums.FriendshipStatus.Approved, 
                cancellationToken);
            var friends = friendships
                .Select(f =>
                {
                    var friend = f.RequesterId == userId ? f.Addressee : f.Requester;
                    return new FriendDto(
                        friend.Id,
                        friend.UserName ?? string.Empty,
                        friend.AvatarUrl,
                        f.Status,
                        f.CreatedAt);
                })
                .ToList();
            return Ok(friends);
        }

        [HttpPost("send-request")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> SendFriendshipRequest([FromBody] FriendRequestDto request,CancellationToken cancellationToken)
        {
            if (!User.TryGetUserId(out var userId))
                return Unauthorized();

            var result = await _addFriendUseCase.ExecuteAsync(new Application.UseCaseContracts.AddFriendRequest(
                userId, 
                request.AddresseeUsername
            ), cancellationToken);

            if (!result.IsSuccess)
                return BadRequest(result.Error);

            return Ok(new FriendDto(
                result.Value.Friendship.Addressee.Id,
                result.Value.Friendship.Addressee.UserName ?? string.Empty,
                result.Value.Friendship.Addressee.AvatarUrl,
                result.Value.Friendship.Status,
                result.Value.Friendship.CreatedAt));
        }

        [HttpPost("get-pending-requests")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> GetUserPendingFriendRequests(CancellationToken cancellationToken)
        {
            if (!User.TryGetUserId(out var userId))
                return Unauthorized();
            var friendships = await _unitOfWork.Friendships.GetUserFriendsAsync(userId, Domain.Enums.FriendshipStatus.Pending,
                cancellationToken);
            var friends = friendships
                .Where(friendship => friendship.AddresseeId == userId && friendship.RequesterId != userId)
                .Select(f => new IncominFriendshipDto(f.Id, f.RequesterId, f.Requester.UserName, f.Status))
                .ToList();
            return Ok(friends);
        }

        [HttpPost("accept")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> GetUserPendingFriendRequests([FromBody] string friendshipId, CancellationToken cancellationToken)
        {
            if (!User.TryGetUserId(out var userId))
                return Unauthorized();
            if (Guid.TryParse(friendshipId, out var friendshipGuid))
            {
                var friendship = await _unitOfWork.Friendships.GetByIdAsync(friendshipGuid, cancellationToken);
                if(friendship.Status == Domain.Enums.FriendshipStatus.Pending)
                {
                    friendship.Status = Domain.Enums.FriendshipStatus.Approved;
                    await _unitOfWork.Friendships.UpdateAsync(friendship, cancellationToken);
                    await _unitOfWork.SaveChangesAsync(cancellationToken);
                }
                return Ok();
            }
            return BadRequest("Invalid friendship ID");
        }
    }
}
