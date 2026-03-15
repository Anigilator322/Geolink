using Geolink.Application.Common;
using Geolink.Application.DTOs.Auth;
using Geolink.Application.Interfaces;
using Geolink.Domain.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Configuration;

namespace Geolink.Infrastructure.Services;

public class AuthService : IAuthService
{
    private readonly UserManager<User> _userManager;
    private readonly IEmailOtpService _otpService;
    private readonly ITokenService _tokenService;
    private readonly IUnitOfWork _unitOfWork;
    private readonly IConfiguration _configuration;

    public AuthService(
        UserManager<User> userManager,
        IEmailOtpService otpService,
        ITokenService tokenService,
        IUnitOfWork unitOfWork,
        IConfiguration configuration)
    {
        _userManager = userManager;
        _otpService = otpService;
        _tokenService = tokenService;
        _unitOfWork = unitOfWork;
        _configuration = configuration;
    }

    public async Task<Result<bool>> SendCodeAsync(string email, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(email))
            return Result<bool>.Failure("Email is required.");

        email = email.Trim();

        var user = await _unitOfWork.Users.GetByEmailAsync(email, cancellationToken);
        if (user == null)
        {
            user = new User
            {
                Email = email,
                UserName = email,
                EmailConfirmed = false,
                Approved = false,
                CreatedAt = DateTime.UtcNow
            };

            var createResult = await _userManager.CreateAsync(user);
            if (!createResult.Succeeded)
            {
                var errors = string.Join(", ", createResult.Errors.Select(e => e.Description));
                return Result<bool>.Failure($"Failed to create user: {errors}");
            }
        }

        await _otpService.SendOtpAsync(email, cancellationToken);
        return Result<bool>.Success(true);
    }

    public async Task<Result<AuthResponse>> VerifyCodeAsync(
        string email,
        string code,
        string? ipAddress = null,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(code))
            return Result<AuthResponse>.Failure("Email and code are required.");

        email = email.Trim();
        code = code.Trim();

        var isValid = await _otpService.VerifyOtpAsync(email, code, cancellationToken);
        if (!isValid)
            return Result<AuthResponse>.Failure("Invalid or expired code.");

        var user = await _unitOfWork.Users.GetByEmailAsync(email, cancellationToken);
        if (user == null)
            return Result<AuthResponse>.Failure("User not found.");

        if (!user.EmailConfirmed)
        {
            user.EmailConfirmed = true;
            user.Approved = true;
            user.UpdatedAt = DateTime.UtcNow;

            await _unitOfWork.Users.UpdateAsync(user, cancellationToken);
        }

        var accessToken = _tokenService.GenerateAccessToken(user);
        var refreshToken = _tokenService.GenerateRefreshToken(ipAddress);

        user.RefreshTokens ??= new List<RefreshToken>();
        refreshToken.UserId = user.Id;
        user.RefreshTokens.Add(refreshToken);
        user.UpdatedAt = DateTime.UtcNow;

        await _unitOfWork.Users.UpdateAsync(user, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        var accessTokenMinutes = int.TryParse(_configuration["Jwt:AccessTokenExpirationMinutes"], out var minutes)
            ? minutes
            : 60;

        var response = new AuthResponse(
            UserId: user.Id,
            Email: user.Email ?? string.Empty,
            Username: user.UserName ?? string.Empty,
            AccessToken: accessToken,
            RefreshToken: refreshToken.Token,
            ExpiresAt: DateTime.UtcNow.AddMinutes(accessTokenMinutes)
        );

        return Result<AuthResponse>.Success(response);
    }
}