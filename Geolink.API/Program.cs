using System.Text;
using Geolink.API.Hubs;
using Geolink.Application;
using Geolink.Infrastructure;
using Geolink.Infrastructure.Options;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;

namespace Geolink.API
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            var defaultConnection = builder.Configuration.GetConnectionString("DefaultConnection");
            var jwtKey = builder.Configuration["Jwt:Key"];
            if (builder.Environment.IsDevelopment() || builder.Environment.IsProduction())
            {
                if (string.IsNullOrWhiteSpace(defaultConnection))
                {
                    throw new InvalidOperationException("Missing ConnectionStrings:DefaultConnection. Configure it via user-secrets or environment variables.");
                }

                if (string.IsNullOrWhiteSpace(jwtKey))
                {
                    throw new InvalidOperationException("Missing Jwt:Key. Configure it via user-secrets or environment variables.");
                }

                if (Encoding.UTF8.GetByteCount(jwtKey) < 32)
                {
                    throw new InvalidOperationException("Jwt:Key must be at least 32 bytes.");
                }
            }

            // Add layers
            builder.Services.AddApplication();
            builder.Services.AddInfrastructure(builder.Configuration);

            // Controllers
            builder.Services.AddControllers();
            
            // SignalR
            builder.Services.AddSignalR();

            // JWT Authentication
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
                    ClockSkew = TimeSpan.Zero
                };

                // Configure SignalR authentication
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

            builder.Services.AddAuthorization();

            // OpenAPI/Swagger
            builder.Services.AddOpenApi();

            // CORS
            builder.Services.AddCors(options =>
            {
                options.AddPolicy("AllowAll", policy =>
                {
                    policy.AllowAnyOrigin()
                          .AllowAnyMethod()
                          .AllowAnyHeader();
                });
            });
            // Yandex Cloud
            builder.Services.Configure<YandexCloudPostboxOptions>(
                builder.Configuration.GetSection("YandexCloudPostbox"));
                
            var app = builder.Build();

            // Configure the HTTP request pipeline.
            if (app.Environment.IsDevelopment())
            {
                app.MapOpenApi();
            }

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
}
