using Microsoft.AspNetCore.Mvc;

namespace Geolink.API.Controllers
{
    [ApiController]
    [Route("api/friends")]
    public class FriendsController : Controller
    {
        public async Task<IActionResult> GetUserFriends(CancellationToken cancellationToken)
        {
            throw new NotImplementedException();
        }
    }
}
