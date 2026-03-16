using Geolink.Application.Common;
using Geolink.Application.DTOs.Location;
using Geolink.Application.Interfaces;
using Geolink.Domain.Entities;

namespace Geolink.Application.UseCases;

public class UpdateUserLocationUseCase : IUpdateUserLocationUseCase
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILocationCacheService _locationCache;

    public UpdateUserLocationUseCase(IUnitOfWork unitOfWork, ILocationCacheService locationCache)
    {
        _unitOfWork = unitOfWork;
        _locationCache = locationCache;
    }

    public async Task<Result<FriendLocationDto>> ExecuteAsync(
        Guid userId,
        UpdateLocationRequest request,
        CancellationToken cancellationToken = default)
    {
        if (userId == Guid.Empty)
            return Result<FriendLocationDto>.Unauthorized("Invalid user context.");

        if (!IsValidCoordinates(request.Latitude, request.Longitude))
            return Result<FriendLocationDto>.Failure("Invalid coordinates.");

        var user = await _unitOfWork.Users.GetByIdAsync(userId, cancellationToken);
        if (user is null)
            return Result<FriendLocationDto>.NotFound("User was not found.");

        var timestamp = DateTime.UtcNow;

        var location = await _unitOfWork.UserLocations.GetByUserIdAsync(userId, cancellationToken);
        if (location is null)
        {
            await _unitOfWork.UserLocations.AddAsync(new UserLocation
            {
                UserId = userId,
                Latitude = request.Latitude,
                Longitude = request.Longitude,
                IsSharing = true
            }, cancellationToken);
        }
        else
        {
            location.Latitude = request.Latitude;
            location.Longitude = request.Longitude;
            location.UpdatedAt = timestamp;
            await _unitOfWork.UserLocations.UpdateAsync(location, cancellationToken);
        }

        await _locationCache.SetLocationAsync(
            userId,
            request.Latitude,
            request.Longitude,
            cancellationToken);

        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return Result<FriendLocationDto>.Success(new FriendLocationDto(
            userId,
            user.UserName ?? string.Empty,
            request.Latitude,
            request.Longitude,
            timestamp));
    }

    private static bool IsValidCoordinates(double latitude, double longitude)
    {
        return latitude >= -90 && latitude <= 90 &&
               longitude >= -180 && longitude <= 180;
    }
}
