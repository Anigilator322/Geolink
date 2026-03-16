using Microsoft.AspNetCore.Authorization;

namespace Geolink.API.Authorization;

public sealed class DevelopmentEnvironmentAuthorizationHandler : AuthorizationHandler<DevelopmentEnvironmentRequirement>
{
    private readonly IWebHostEnvironment _environment;

    public DevelopmentEnvironmentAuthorizationHandler(IWebHostEnvironment environment)
    {
        _environment = environment;
    }

    protected override Task HandleRequirementAsync(
        AuthorizationHandlerContext context,
        DevelopmentEnvironmentRequirement requirement)
    {
        if (_environment.IsDevelopment())
            context.Succeed(requirement);

        return Task.CompletedTask;
    }
}
