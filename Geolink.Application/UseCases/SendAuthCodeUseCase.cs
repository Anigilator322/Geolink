using Geolink.Application.Common;
using Geolink.Application.Interfaces;
using Geolink.Application.UseCaseContracts;
using Geolink.Domain.Entities;
using Microsoft.Extensions.Configuration;
using System.Threading;

namespace Geolink.Application.UseCases
{
    public class SendAuthCodeUseCase : UseCaseBase<SendAuthCodeResponse, SendAuthCodeRequest>, ISendAuthCodeUseCase
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly IUserService _userService;
        private readonly ITokenService _tokenService;
        private readonly IConfiguration _configuration;

        public SendAuthCodeUseCase(
            IUnitOfWork unitOfWork,
            IUserService userService,
            ITokenService tokenService,
            IConfiguration configuration)
        {
            _unitOfWork = unitOfWork;
            _userService = userService;
            _tokenService = tokenService;
            _configuration = configuration;
        }

        public override async Task<Result<SendAuthCodeResponse>> ExecuteAsync(SendAuthCodeRequest request, CancellationToken ct)
        {
            if (string.IsNullOrWhiteSpace(request.Email))
                return Result<SendAuthCodeResponse>.Failure("Email is required.");

            var emailTrimmed = request.Email.Trim();

            var user = await _unitOfWork.Users.GetByEmailAsync(emailTrimmed, ct);
            if (user == null)
            {
                user = new User
                {
                    Email = emailTrimmed,
                    UserName = emailTrimmed,
                    EmailConfirmed = false,
                    Approved = false,
                    CreatedAt = DateTime.UtcNow
                };

                var createResult = await _userService.CreateUserAsync(user);
                if (!createResult)
                {
                    return Result<SendAuthCodeResponse>.Failure($"Failed to create user");
                }
            }

            if (!user.EmailConfirmed || !user.Approved)
            {
                user.EmailConfirmed = true;
                user.Approved = true;
                user.UpdatedAt = DateTime.UtcNow;

                await _unitOfWork.Users.UpdateAsync(user, ct);
            }

            var accessToken = _tokenService.GenerateAccessToken(user);
            var refreshToken = _tokenService.GenerateRefreshToken(ipAddress: null);

            user.RefreshTokens ??= new List<RefreshToken>();
            refreshToken.UserId = user.Id;
            user.RefreshTokens.Add(refreshToken);
            user.UpdatedAt = DateTime.UtcNow;

            await _unitOfWork.Users.UpdateAsync(user, ct);
            await _unitOfWork.SaveChangesAsync(ct);

            var accessTokenMinutes = int.TryParse(_configuration["Jwt:AccessTokenExpirationMinutes"], out var minutes)
                ? minutes
                : 60;

            return Result<SendAuthCodeResponse>.Success(
                new SendAuthCodeResponse(
                    UserId: user.Id,
                    Email: user.Email ?? string.Empty,
                    Username: user.UserName ?? string.Empty,
                    AccessToken: accessToken,
                    RefreshToken: refreshToken.Token,
                    ExpiresAt: DateTime.UtcNow.AddMinutes(accessTokenMinutes)));
        }
    }
}
