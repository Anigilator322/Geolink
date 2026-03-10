using Geolink.Application.Common;
using Geolink.Application.DTOs.Auth;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace Geolink.Infrastructure.Services;

public class AuthService : IAuthService
{
    private readonly UserManager<User> _userManager;
    private readonly IUserRepository _userRepository;

    public AuthService(
        UserManager<User> userManager,
        IEmailOtpService otpService,
        ITokenService tokenService,
        IUserRepository userRepository)
    {
        _userManager = userManager;
        _otpService = otpService;
        _tokenService = tokenService;
        _userRepository = userRepository;
    }

    public async Task<Result<bool>> SendCodeAsync(string email, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(email))
            return Result<bool>.Failure("Email is required");

        var user = await _userRepository.GetByEmailAsync(email, cancellationToken);
        
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

        var user = await _userRepository.GetByEmailAsync(email, cancellationToken);
        if (user == null)
            return Result<AuthResponse>.Failure("User not found");

        if (!user.EmailConfirmed)
        {
            user.EmailConfirmed = true;
            user.Approved = true;
            await _userRepository.UpdateAsync(user, cancellationToken);
        }

        var accessToken = _tokenService.GenerateAccessToken(user);
        var refreshToken = _tokenService.GenerateRefreshToken();

        user.RefreshTokens.Add(refreshToken);
        refreshToken.UserId = user.Id;
        await _userRepository.UpdateAsync(user, cancellationToken);

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

