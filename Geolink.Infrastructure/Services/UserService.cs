using Geolink.Application.Interfaces;
using Geolink.Domain.Entities;
using Microsoft.AspNetCore.Identity;

namespace Geolink.Infrastructure.Services
{
    public class UserService : IUserService
    {
        private readonly UserManager<User> _userManager;
        private readonly IUnitOfWork _unitOfWork;

        public UserService(UserManager<User> userManager, IUnitOfWork unitOfWork)
        {
            _userManager = userManager;
            _unitOfWork = unitOfWork;
        }

        public async Task<bool> CreateUserAsync(User user)
        {
            var createResult = await _userManager.CreateAsync(user);
            if (!createResult.Succeeded)
            {
                var errors = string.Join(", ", createResult.Errors.Select(e => e.Description));
                return false;
            }
            return createResult.Succeeded;
        }

        public async Task<User> GetUserAsync(Guid userId)
        {
            return await _unitOfWork.Users.GetByIdAsync(userId);
        }
    }
}
