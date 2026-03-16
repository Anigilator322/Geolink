using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

namespace Geolink.API.Common;

public static class ClaimsPrincipalExtensions
{
    public static Guid? GetUserId(this ClaimsPrincipal? principal)
    {
        if (principal is null)
            return null;

        var userIdClaim = principal.FindFirstValue(ClaimTypes.NameIdentifier) ??
                          principal.FindFirstValue(JwtRegisteredClaimNames.Sub) ??
                          principal.FindFirstValue("sub");

        return Guid.TryParse(userIdClaim, out var userId) ? userId : null;
    }

    public static bool TryGetUserId(this ClaimsPrincipal? principal, out Guid userId)
    {
        userId = principal.GetUserId() ?? Guid.Empty;
        return userId != Guid.Empty;
    }
}
