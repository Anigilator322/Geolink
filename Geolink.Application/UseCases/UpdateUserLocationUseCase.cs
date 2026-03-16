using Geolink.Application.Common;
using Geolink.Application.Interfaces;
using Geolink.Application.UseCaseContracts;
using Geolink.Domain.Entities;

namespace Geolink.Application.UseCases;

public class UpdateUserLocationUseCase : UseCaseBase<UpdateLocationResponse, UpdateLocationRequest>, IUpdateUserLocationUseCase
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILocationCacheService _locationCache;

    public UpdateUserLocationUseCase(IUnitOfWork unitOfWork, ILocationCacheService locationCache)
    {
        _unitOfWork = unitOfWork;
        _locationCache = locationCache;
    }

    public override async Task<Result<UpdateLocationResponse>> ExecuteAsync(
        UpdateLocationRequest request,
        CancellationToken cancellationToken = default)
    {
        if (request.UserId == Guid.Empty)
            return Result<UpdateLocationResponse>.Unauthorized("Invalid user context.");

        if (!IsValidCoordinates(request.Latitude, request.Longitude))
            return Result<UpdateLocationResponse>.Failure("Invalid coordinates.");

        var user = await _unitOfWork.Users.GetByIdAsync(request.UserId, cancellationToken);
        if (user is null)
            return Result<UpdateLocationResponse>.NotFound("User was not found.");

        var timestamp = DateTime.UtcNow;

        var location = await _unitOfWork.UserLocations.GetByUserIdAsync(request.UserId, cancellationToken);
        if (location is null)
        {
            await _unitOfWork.UserLocations.AddAsync(new UserLocation
            {
                UserId = request.UserId,
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
            request.UserId,
            request.Latitude,
            request.Longitude,
            cancellationToken);

        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return Result<UpdateLocationResponse>.Success(new UpdateLocationResponse(
            request.UserId,
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
