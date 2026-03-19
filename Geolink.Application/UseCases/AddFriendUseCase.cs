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
            if (user is null)
                return Result<AddFriendResponse>.NotFound("Issuer user not found");

            var addressee = await _unitOfWork.Users.GetByEmailAsync(request.AddresseeUsername, ct);
            if (addressee is null)
                return Result<AddFriendResponse>.NotFound("Addressee user not found");

            if (user.Id == addressee.Id)
                return Result<AddFriendResponse>.Failure("You cannot send a friend request to yourself");

            var existingFriendship = await _unitOfWork.Friendships.GetFriendshipAsync(user.Id, addressee.Id, ct);
            if (existingFriendship is not null)
            {
                return Result<AddFriendResponse>.Success(new AddFriendResponse(existingFriendship));
            }

            var newFriendship = new Geolink.Domain.Entities.Friendship
            {
                RequesterId = user.Id,
                AddresseeId = addressee.Id,
                Status = Geolink.Domain.Enums.FriendshipStatus.Pending
            };

            var friendship = await _unitOfWork.Friendships.AddAsync(newFriendship, ct);
            try
            {
                await _unitOfWork.SaveChangesAsync(ct);
            }
            catch (Exception) when (!ct.IsCancellationRequested)
            {
                var savedFriendship = await _unitOfWork.Friendships.GetFriendshipAsync(user.Id, addressee.Id, ct);
                if (savedFriendship is not null)
                    return Result<AddFriendResponse>.Success(new AddFriendResponse(savedFriendship));

                throw;
            }

            return Result<AddFriendResponse>.Success(new AddFriendResponse(friendship));
        }
    }
}
