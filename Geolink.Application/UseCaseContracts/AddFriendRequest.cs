using Geolink.Domain.Entities;

namespace Geolink.Application.UseCaseContracts
{
    public record AddFriendRequest(Guid IssuerId, string AddresseeUsername);
    public record AddFriendResponse(Friendship Friendship);
}
