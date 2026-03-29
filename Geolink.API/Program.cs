using System.IdentityModel.Tokens.Jwt;
using System.Text;
using Geolink.API.Authorization;
using Geolink.API.Hubs;
using Geolink.API.Realtime;
using Geolink.Application;
using Geolink.Infrastructure;
using Geolink.Infrastructure.Data;
using Geolink.Infrastructure.Options;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

namespace Geolink.API;

public class Program
{
    public static void Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);

        builder.Host.UseDefaultServiceProvider(options =>
        {
            options.ValidateScopes = builder.Environment.IsDevelopment();
            options.ValidateOnBuild = true;
        });

        var defaultConnection = builder.Configuration.GetConnectionString("DefaultConnection");
        var redisConnection = builder.Configuration.GetConnectionString("Redis");
        var jwtKey = builder.Configuration["Jwt:Key"];

        if (builder.Environment.IsDevelopment() || builder.Environment.IsStaging() || builder.Environment.IsProduction())
        {
            if (string.IsNullOrWhiteSpace(defaultConnection))
            {
                throw new InvalidOperationException(
                    "Missing ConnectionStrings:DefaultConnection. Configure it via appsettings or environment variables.");
            }

            if (string.IsNullOrWhiteSpace(redisConnection))
            {
                throw new InvalidOperationException(
                    "Missing ConnectionStrings:Redis. Configure it via appsettings or environment variables.");
            }

            if (string.IsNullOrWhiteSpace(jwtKey))
            {
                throw new InvalidOperationException(
                    "Missing Jwt:Key. Configure it via appsettings or environment variables.");
            }

            if (Encoding.UTF8.GetByteCount(jwtKey) < 32)
            {
                throw new InvalidOperationException("Jwt:Key must be at least 32 bytes.");
            }
        }

        builder.Services.AddApplication();
        builder.Services.AddInfrastructure(builder.Configuration);

        builder.Services.AddControllers();
        builder.Services.AddSignalR();

        builder.Services.AddSingleton<IUserConnectionRegistry, UserConnectionRegistry>();
        builder.Services.AddScoped<IFriendLocationBroadcastService, FriendLocationBroadcastService>();

        var jwtSettings = builder.Configuration.GetSection("Jwt");

        builder.Services.AddAuthentication(options =>
        {
            options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
            options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
        })
        .AddJwtBearer(options =>
        {
            options.TokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey!)),
                ValidateIssuer = true,
                ValidIssuer = jwtSettings["Issuer"],
                ValidateAudience = true,
                ValidAudience = jwtSettings["Audience"],
                ValidateLifetime = true,
                ClockSkew = TimeSpan.Zero,
                NameClaimType = JwtRegisteredClaimNames.Sub
            };

            options.Events = new JwtBearerEvents
            {
                OnMessageReceived = context =>
                {
                    var accessToken = context.Request.Query["access_token"];
                    var path = context.HttpContext.Request.Path;
                    if (!string.IsNullOrEmpty(accessToken) && path.StartsWithSegments("/hubs"))
                    {
                        context.Token = accessToken;
                    }

                    return Task.CompletedTask;
                }
            };
        });

        builder.Services.AddAuthorization(options =>
        {
            options.AddPolicy("DevelopmentOnly", policy =>
            {
                policy.RequireAuthenticatedUser();
                policy.AddRequirements(new DevelopmentEnvironmentRequirement());
            });
        });
        builder.Services.AddSingleton<IAuthorizationHandler, DevelopmentEnvironmentAuthorizationHandler>();

        builder.Services.AddOpenApi();

        builder.Services.AddCors(options =>
        {
            options.AddPolicy("AllowAll", policy =>
            {
                policy.AllowAnyOrigin()
                    .AllowAnyMethod()
                    .AllowAnyHeader();
            });
        });

        builder.Services.Configure<YandexCloudPostboxOptions>(
            builder.Configuration.GetSection("YandexCloudPostbox"));

        var app = builder.Build();
        
        using (var scope = app.Services.CreateScope())
        {
            var dbContext = scope.ServiceProvider.GetRequiredService<GeolinkDbContext>();
            dbContext.Database.Migrate();
        }

        app.MapOpenApi();

        if (!app.Environment.IsDevelopment())
        {
            app.UseHttpsRedirection();
        }

        app.UseCors("AllowAll");

        app.UseAuthentication();
        app.UseAuthorization();

        app.MapControllers();
        app.MapHub<GeolinkHub>("/hubs/geolink");

        app.Run();
    }
}
