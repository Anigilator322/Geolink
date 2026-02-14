using Geolink.Domain.Entities;

namespace Geolink.Application.Interfaces;

public interface ITokenService
{
    string GenerateAccessToken(User user);
    RefreshToken GenerateRefreshToken(string? ipAddress = null);
    Guid? ValidateAccessToken(string token);
}
