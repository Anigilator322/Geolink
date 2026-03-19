using Geolink.API.Common;
using Geolink.Application.DTOs.Users;
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

        [HttpGet()]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> GetProfile()
        {
            if (!User.TryGetUserId(out var userId))
                return Unauthorized();
            var user = await _userService.GetUserAsync(userId);
            if (user == null) return NotFound();
            return Ok(new
            {
                Name = user.UserName,
                Bio = user.Bio,
            });
        }

        [HttpPut()]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> UpdateProfile([FromBody] UpdateProfileRequest request)
        {
            if (!User.TryGetUserId(out var userId))
                return Unauthorized();

            var user = await _userService.GetUserAsync(userId);
            
            if (request.Username != null)
                user.UserName = request.Username;
            if (request.Bio != null)
                user.Bio = request.Bio;

            var result = await _userService.UpdateUserAsync(user);
            if (!result)
                return BadRequest(new { error = "Failed to update profile" });

            return Ok(new
            {
                Name = user.UserName,
                Bio = user.Bio,
            });
        }
    }
}
