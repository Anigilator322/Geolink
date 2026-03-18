using Geolink.Application.Common;
using Geolink.Application.Interfaces;
using Geolink.Application.UseCaseContracts;
using Microsoft.Extensions.Configuration;

namespace Geolink.Application.UseCases;

public class RefreshTokenUseCase : UseCaseBase<RefreshTokenResponse, RefreshTokenRequest>, IRefreshTokenUseCase
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ITokenService _tokenService;
    private readonly IConfiguration _configuration;

    public RefreshTokenUseCase(
        IUnitOfWork unitOfWork,
        ITokenService tokenService,
        IConfiguration configuration)
    {
        _unitOfWork = unitOfWork;
        _tokenService = tokenService;
        _configuration = configuration;
    }

    public override async Task<Result<RefreshTokenResponse>> ExecuteAsync(
        RefreshTokenRequest request,
        CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(request.RefreshToken))
        {
            return Result<RefreshTokenResponse>.Failure("Refresh token is required.");
        }

        var existingRefreshToken = await _unitOfWork.RefreshTokens.GetByTokenAsync(
            request.RefreshToken.Trim(),
            ct);

        if (existingRefreshToken == null || !existingRefreshToken.IsActive)
        {
            return Result<RefreshTokenResponse>.Unauthorized("Invalid or expired refresh token.");
        }

        var user = existingRefreshToken.User;
        if (user == null)
        {
            return Result<RefreshTokenResponse>.Unauthorized("Invalid refresh token owner.");
        }

        var newAccessToken = _tokenService.GenerateAccessToken(user);
        var newRefreshToken = _tokenService.GenerateRefreshToken(request.IpAddress);
        newRefreshToken.UserId = user.Id;

        existingRefreshToken.IsRevoked = true;
        existingRefreshToken.RevokedAt = DateTime.UtcNow;
        existingRefreshToken.RevokedByIp = request.IpAddress;
        existingRefreshToken.ReplacedByToken = newRefreshToken.Token;

        user.UpdatedAt = DateTime.UtcNow;

        await _unitOfWork.RefreshTokens.UpdateAsync(existingRefreshToken, ct);
        await _unitOfWork.RefreshTokens.AddAsync(newRefreshToken, ct);
        await _unitOfWork.Users.UpdateAsync(user, ct);
        await _unitOfWork.SaveChangesAsync(ct);

        var accessTokenMinutes = int.TryParse(
            _configuration["Jwt:AccessTokenExpirationMinutes"],
            out var minutes)
            ? minutes
            : 60;

        var response = new RefreshTokenResponse(
            UserId: user.Id,
            Email: user.Email ?? string.Empty,
            Username: user.UserName ?? string.Empty,
            AccessToken: newAccessToken,
            RefreshToken: newRefreshToken.Token,
            ExpiresAt: DateTime.UtcNow.AddMinutes(accessTokenMinutes)
        );

        return Result<RefreshTokenResponse>.Success(response);
    }
}
