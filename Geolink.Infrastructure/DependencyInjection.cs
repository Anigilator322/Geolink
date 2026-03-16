using Geolink.Application.Interfaces;
using Geolink.Domain.Entities;
using Geolink.Infrastructure.Data;
using Geolink.Infrastructure.Services;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using StackExchange.Redis;
using Geolink.Infrastructure.Options;
using Geolink.Application.UseCases;
using Geolink.Application.Services;

namespace Geolink.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        // База данных
        services.AddDbContext<GeolinkDbContext>(options =>
            options.UseNpgsql(configuration.GetConnectionString("DefaultConnection")));

        // ASP.NET Core Identity (без ролей, беспарольный поток)
        services.AddIdentityCore<User>(options =>
            {
                options.User.RequireUniqueEmail = true;
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
        if (string.IsNullOrWhiteSpace(redisConnection))
            throw new InvalidOperationException("Missing ConnectionStrings:Redis. Redis is required.");

        services.AddSingleton<IConnectionMultiplexer>(_ => ConnectionMultiplexer.Connect(redisConnection));
        services.AddScoped<ILocationCacheService, LocationCacheService>();

        // Репозитории и Unit of Work
        services.AddScoped<IUnitOfWork, UnitOfWork>();

        // Сервисы
        services.AddScoped<ITokenService, TokenService>();
        services.AddScoped<IEmailOtpService, EmailOtpService>();
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IFriendsMapService, FriendsMapService>();
        services.AddScoped<IHubActionAuthorizationService, HubActionAuthorizationService>();

        //Usecases
        services.AddScoped<IUpdateUserLocationUseCase, UpdateUserLocationUseCase>();

        // Конфигурация YandexCloudPostbox
        services.Configure<YandexCloudPostboxOptions>(
            configuration.GetSection(YandexCloudPostboxOptions.SectionName));
        
        // Yandex Cloud email sender
        services.AddHttpClient<YandexCloudEmailSender>();

        var useYandexPostbox = configuration.GetValue<bool>("YandexCloudPostbox:Enabled");

        if (useYandexPostbox)
        {
            services.AddScoped<IEmailSender>(sp =>
                sp.GetRequiredService<YandexCloudEmailSender>());
        }
        else
        {
            services.AddScoped<IEmailSender, ConsoleEmailSender>();
        }
        return services;
    }
}
