using Geolink.API.Common;
using Geolink.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Geolink.API.Controllers
{
    [ApiController]
    [Route("api/me")]
    public class UserController : ControllerBase
    {
        private readonly IUserService _userService;

        public UserController(IUserService userService)
        {
            _userService = userService;
        }

        [HttpPost()]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> Index()
        {
            if (!User.TryGetUserId(out var userId))
                return Unauthorized();
            var user = await _userService.GetUserAsync(userId);
            return Ok(new
            {
                Name = user.UserName,
                Bio = user.Bio,
            });
        }
    }
}
