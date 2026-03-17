using Geolink.Domain.Entities;

namespace Geolink.Application.Interfaces
{
    public interface IUserService
    {
        public Task<bool> CreateUserAsync(User user);
        public Task<User> GetUserAsync(Guid userId);
    }
}
