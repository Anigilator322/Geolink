using Microsoft.AspNetCore.Authorization;

namespace Geolink.API.Authorization;

public sealed class DevelopmentEnvironmentRequirement : IAuthorizationRequirement
{
}
