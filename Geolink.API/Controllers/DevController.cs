using System.Security.Claims;
using Geolink.Application.Interfaces;
using Geolink.Domain.Entities;
using Geolink.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Geolink.API.Controllers;

[ApiController]
[Route("api/dev")]
[Authorize]
public class DevController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILocationCacheService _locationCache;
    private readonly ILogger<DevController> _logger;

    private static readonly (string Email, double Latitude, double Longitude)[] TestFriends = new[]
    {
        ("friend1@test.com", 55.751244, 37.618423),
        ("friend2@test.com", 55.760000, 37.620000),
        ("friend3@test.com", 55.745000, 37.610000)
    };

    public DevController(
        IUnitOfWork unitOfWork,
        ILocationCacheService locationCache,
        ILogger<DevController> logger)
    {
        _unitOfWork = unitOfWork;
        _locationCache = locationCache;
        _logger = logger;
    }

    /// <summary>
    /// Создать тестовых друзей и их локации для development
    /// </summary>
    [HttpPost("seed-friends")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> SeedFriends(CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();
        if (userId == Guid.Empty)
            return Unauthorized();

        try
        {
            foreach (var (email, latitude, longitude) in TestFriends)
            {
                var friend = await _unitOfWork.Users.GetByEmailAsync(email, cancellationToken);

                if (friend == null)
                {
                    friend = new User
                    {
                        Id = Guid.NewGuid(),
                        Email = email,
                        NormalizedEmail = email.ToUpper(),
                        UserName = email.Split('@')[0],
                        NormalizedUserName = email.Split('@')[0].ToUpper(),
                        EmailConfirmed = true,
                        CreatedAt = DateTime.UtcNow,
                        Approved = true
                    };

                    await _unitOfWork.Users.AddAsync(friend, cancellationToken);
                    await _unitOfWork.SaveChangesAsync(cancellationToken);
                }

                var friendship = await _unitOfWork.Friendships.GetFriendshipAsync(
                    userId, 
                    friend.Id, 
                    cancellationToken);

                if (friendship == null)
                {
                    friendship = new Friendship
                    {
                        Id = Guid.NewGuid(),
                        RequesterId = userId,
                        AddresseeId = friend.Id,
                        Status = FriendshipStatus.Approved,
                        AcceptedAt = DateTime.UtcNow
                    };

                    await _unitOfWork.Friendships.AddAsync(friendship, cancellationToken);
                    await _unitOfWork.SaveChangesAsync(cancellationToken);
                }

                await _locationCache.SetLocationAsync(
                    friend.Id,
                    latitude,
                    longitude,
                    cancellationToken);

                _logger.LogInformation($"Created/updated friend: {email} with location ({latitude}, {longitude})");
            }

            return Ok(new { message = "Mock friends created" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error seeding friends");
            return StatusCode(StatusCodes.Status500InternalServerError, "Failed to seed friends");
        }
    }

    private Guid GetCurrentUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        if (userIdClaim?.Value != null && Guid.TryParse(userIdClaim.Value, out var userId))
            return userId;

        return Guid.Empty;
    }
}
