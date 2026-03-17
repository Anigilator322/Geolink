using Geolink.Application.Common;
using Geolink.Application.UseCaseContracts;

namespace Geolink.Application.Interfaces
{
    public interface IAddFriendUseCase
    {
        public Task<Result<AddFriendResponse>> ExecuteAsync(AddFriendRequest request, CancellationToken ct);
    }
}
