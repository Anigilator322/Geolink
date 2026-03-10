using Geolink.Application.Common;
using Geolink.Application.DTOs.Auth;
using Geolink.Application.Interfaces;
using Geolink.Domain.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace Geolink.Infrastructure.Services;

public class AuthService : IAuthService
{
    private readonly UserManager<User> _userManager;
    private readonly IEmailOtpService _otpService;
    private readonly ITokenService _tokenService;
    private readonly IUnitOfWork _unitOfWork;

    public AuthService(
        UserManager<User> userManager,
        IEmailOtpService otpService,
        ITokenService tokenService,
        IUnitOfWork unitOfWork)
    {
        _userManager = userManager;
        _otpService = otpService;
        _tokenService = tokenService;
        _unitOfWork = unitOfWork;
    }

    public async Task<Result<bool>> SendCodeAsync(string email, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(email))
            return Result<bool>.Failure("Email is required");

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

            var result = await _userManager.CreateAsync(user);
            if (!result.Succeeded)
                return Result<bool>.Failure($"Failed to create user: {string.Join(", ", result.Errors.Select(e => e.Description))}");
        }

        await _otpService.SendOtpAsync(email, cancellationToken);

        return Result<bool>.Success(true);
    }

    public async Task<Result<AuthResponse>> VerifyCodeAsync(string email, string code, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(code))
            return Result<AuthResponse>.Failure("Email and code are required");

        var isValid = await _otpService.VerifyOtpAsync(email, code, cancellationToken);
        if (!isValid)
            return Result<AuthResponse>.Failure("Invalid or expired code");

        var user = await _unitOfWork.Users.GetByEmailAsync(email, cancellationToken);
        if (user == null)
            return Result<AuthResponse>.Failure("User not found");

        if (!user.EmailConfirmed)
        {
            user.EmailConfirmed = true;
            user.Approved = true;
            await _unitOfWork.Users.UpdateAsync(user, cancellationToken);
        }

        var accessToken = _tokenService.GenerateAccessToken(user);
        var refreshToken = _tokenService.GenerateRefreshToken();

        user.RefreshTokens.Add(refreshToken);
        refreshToken.UserId = user.Id;
        await _unitOfWork.Users.UpdateAsync(user, cancellationToken);

        var response = new AuthResponse(
            UserId: user.Id,
            Email: user.Email ?? "",
            Username: user.UserName ?? "",
            AccessToken: accessToken,
            RefreshToken: refreshToken.Token,
            ExpiresAt: refreshToken.ExpiresAt
        );

        return Result<AuthResponse>.Success(response);
    }

    public async Task<Result<AuthResponse>> RefreshTokenAsync(string refreshToken, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(refreshToken))
            return Result<AuthResponse>.Failure("Refresh token is required");

        var user = await _userManager.Users
            .FirstOrDefaultAsync(u => u.RefreshTokens.Any(rt => rt.Token == refreshToken), cancellationToken);

        if (user == null)
            return Result<AuthResponse>.Failure("Invalid refresh token");

        var tokenRecord = user.RefreshTokens.FirstOrDefault(rt => rt.Token == refreshToken);
        if (tokenRecord == null || tokenRecord.ExpiresAt < DateTime.UtcNow)
            return Result<AuthResponse>.Failure("Refresh token expired");

        var newAccessToken = _tokenService.GenerateAccessToken(user);
        var newRefreshToken = _tokenService.GenerateRefreshToken();

        user.RefreshTokens.Remove(tokenRecord);
        user.RefreshTokens.Add(newRefreshToken);
        newRefreshToken.UserId = user.Id;
        await _unitOfWork.Users.UpdateAsync(user, cancellationToken);

        var response = new AuthResponse(
            UserId: user.Id,
            Email: user.Email ?? "",
            Username: user.UserName ?? "",
            AccessToken: newAccessToken,
            RefreshToken: newRefreshToken.Token,
            ExpiresAt: newRefreshToken.ExpiresAt
        );

        return Result<AuthResponse>.Success(response);
    }
}
