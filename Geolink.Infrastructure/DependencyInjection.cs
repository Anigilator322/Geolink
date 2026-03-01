using Geolink.Application.Interfaces;
using Geolink.Domain.Entities;
using Geolink.Infrastructure.Data;
using Geolink.Infrastructure.Services;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using StackExchange.Redis;

namespace Geolink.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        // Database
        services.AddDbContext<GeolinkDbContext>(options =>
            options.UseNpgsql(configuration.GetConnectionString("DefaultConnection")));

        // ASP.NET Core Identity (no roles, passwordless flow)
        services.AddIdentityCore<User>(options =>
            {
                options.User.RequireUniqueEmail = true;
                // Password requirements are irrelevant (OTP-only login),
                // but set minimums in case UserManager.AddPasswordAsync is ever called
                options.Password.RequireDigit = false;
                options.Password.RequireUppercase = false;
                options.Password.RequireNonAlphanumeric = false;
                options.Password.RequiredLength = 1;
            })
            .AddRoles<IdentityRole<Guid>>()
            .AddEntityFrameworkStores<GeolinkDbContext>()
            .AddDefaultTokenProviders();

        // Redis
        var redisConnection = configuration.GetConnectionString("Redis");
        if (!string.IsNullOrEmpty(redisConnection))
        {
            services.AddSingleton<IConnectionMultiplexer>(ConnectionMultiplexer.Connect(redisConnection));
            services.AddScoped<ILocationCacheService, LocationCacheService>();
        }

        // Repositories & UoW
        services.AddScoped<IUnitOfWork, UnitOfWork>();

        // Services
        services.AddScoped<ITokenService, TokenService>();
        services.AddScoped<IEmailOtpService, EmailOtpService>();
        services.AddScoped<IEmailSender, ConsoleEmailSender>();

        return services;
    }
}
