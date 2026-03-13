using System.Security.Claims;
using Geolink.Application.DTOs.Location;
using Geolink.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Geolink.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class LocationController : ControllerBase
{
    private readonly ILocationCacheService _locationCache;
    private readonly IFriendsMapService _friendsMap;

    public LocationController(
        ILocationCacheService locationCache,
        IFriendsMapService friendsMap)
    {
        _locationCache = locationCache;
        _friendsMap = friendsMap;
    }

    /// <summary>
    /// Обновить текущую геолокацию пользователя
    /// </summary>
    [HttpPut]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> UpdateLocation(
        [FromBody] UpdateLocationRequest request,
        CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();
        if (userId == Guid.Empty)
            return Unauthorized();

        // Валидация координат
        if (request.Latitude < -90 || request.Latitude > 90 ||
            request.Longitude < -180 || request.Longitude > 180)
            return BadRequest("Invalid coordinates.");

        await _locationCache.SetLocationAsync(
            userId,
            request.Latitude,
            request.Longitude,
            cancellationToken);

        return NoContent();
    }

    /// <summary>
    /// Получить список друзей с их актуальными геолокациями на карте
    /// </summary>
    [HttpGet("friends/map")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<IEnumerable<FriendLocationDto>>> GetFriendsMap(
        CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();
        if (userId == Guid.Empty)
            return Unauthorized();

        var friends = await _friendsMap.GetFriendsWithLocationsAsync(userId, cancellationToken);
        return Ok(friends);
    }

    /// <summary>
    /// Получить текущий userId из JWT claims
    /// </summary>
    private Guid GetCurrentUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        if (userIdClaim?.Value != null && Guid.TryParse(userIdClaim.Value, out var userId))
            return userId;

        return Guid.Empty;
    }
}
