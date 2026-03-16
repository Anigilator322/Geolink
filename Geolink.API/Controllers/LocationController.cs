using Geolink.API.Common;
using Geolink.API.Realtime;
using Geolink.Application.DTOs.Location;
using Geolink.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Geolink.API.Controllers;

[ApiController]
[Route("api/location")]
[Authorize]
public class LocationController : ControllerBase
{
    private readonly IFriendsMapService _friendsMap;
    private readonly IUpdateUserLocationUseCase _updateUserLocation;
    private readonly IFriendLocationBroadcastService _friendLocationBroadcast;

    public LocationController(
        IFriendsMapService friendsMap,
        IUpdateUserLocationUseCase updateUserLocation,
        IFriendLocationBroadcastService friendLocationBroadcast)
    {
        _friendsMap = friendsMap;
        _updateUserLocation = updateUserLocation;
        _friendLocationBroadcast = friendLocationBroadcast;
    }

    [HttpPut]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> UpdateLocation(
        [FromBody] UpdateLocationRequest request,
        CancellationToken cancellationToken)
    {
        if (!User.TryGetUserId(out var userId))
            return Unauthorized();

        var result = await _updateUserLocation.ExecuteAsync(new Application.UseCaseContracts.UpdateLocationRequest(userId, 
            request.Latitude, 
            request.Longitude
        ), cancellationToken);
        if (!result.IsSuccess)
            return StatusCode(result.StatusCode ?? StatusCodes.Status400BadRequest, result.Error);
        var friendLocation = new FriendLocationDto(result.Value.UserId,
            result.Value.Username,
            result.Value.Latitude,
            result.Value.Longitude,
            result.Value.UpdatedAtUtc);

        await _friendLocationBroadcast.BroadcastFriendLocationUpdatedAsync(friendLocation, cancellationToken);

        return NoContent();
    }

    [HttpGet("friends/map")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<IEnumerable<FriendLocationDto>>> GetFriendsMap(
        CancellationToken cancellationToken)
    {
        if (!User.TryGetUserId(out var userId))
            return Unauthorized();

        var friends = await _friendsMap.GetFriendsWithLocationsAsync(userId, cancellationToken);
        return Ok(friends);
    }
}