using Geolink.Application.Common;
using Geolink.Application.Interfaces;
using Geolink.Application.UseCaseContracts;

namespace Geolink.Application.UseCases
{
    public class AddFriendUseCase : UseCaseBase<AddFriendResponse, AddFriendRequest>, IAddFriendUseCase
    {
        private IUnitOfWork _unitOfWork;
        public AddFriendUseCase(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async override Task<Result<AddFriendResponse>> ExecuteAsync(AddFriendRequest request, CancellationToken ct)
        {
            var user = await _unitOfWork.Users.GetByIdAsync(request.IssuerId, ct);
            if(user is null)
                return Result<AddFriendResponse>.NotFound("Issuer user not found");

            var addressee = await _unitOfWork.Users.GetByUsernameAsync(request.AddresseeUsername, ct);
            if(addressee is null)
                return Result<AddFriendResponse>.NotFound("Addressee user not found");

            var isFriendshipExist = await _unitOfWork.Friendships.AreFriendsAsync(user.Id, addressee.Id, ct);
            if (isFriendshipExist)
            {
                var existingFriendship = await _unitOfWork.Friendships.GetFriendshipAsync(user.Id, addressee.Id, ct);
                return Result<AddFriendResponse>.Success(new AddFriendResponse(existingFriendship));
            }

            var newFriendship = new Geolink.Domain.Entities.Friendship
            {
                RequesterId = user.Id,
                AddresseeId = addressee.Id,
                Status = Geolink.Domain.Enums.FriendshipStatus.Pending
            };

            var friendship = await _unitOfWork.Friendships.AddAsync(newFriendship, ct);
            await _unitOfWork.SaveChangesAsync(ct);
            return Result<AddFriendResponse>.Success(new AddFriendResponse(friendship));
        }
    }
}
