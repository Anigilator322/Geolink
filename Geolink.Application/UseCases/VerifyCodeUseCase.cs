using Geolink.Application.Common;
using Geolink.Application.Interfaces;
using Geolink.Application.UseCaseContracts;
using Geolink.Domain.Entities;
using Microsoft.Extensions.Configuration;

namespace Geolink.Application.UseCases
{
    public class VerifyCodeUseCase : UseCaseBase<VerifyCodeResponse, VerifyCodeRequest>, IVerifyCodeUseCase
    {
        private readonly IEmailOtpService _otpService;
        private readonly IUnitOfWork _unitOfWork;
        private readonly ITokenService _tokenService;
        private readonly IConfiguration _configuration;

        public VerifyCodeUseCase(IEmailOtpService otpService, IUnitOfWork unitOfWork, ITokenService tokenService, IConfiguration configuration)
        {
            _otpService = otpService;
            _unitOfWork = unitOfWork;
            _tokenService = tokenService;
            _configuration = configuration;
        }

        public override async Task<Result<VerifyCodeResponse>> ExecuteAsync(VerifyCodeRequest request, CancellationToken ct)
        {
            if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Code))
                return Result<VerifyCodeResponse>.Failure("Email and Code are required.");

            var email = request.Email.Trim();
            var code = request.Code.Trim();

            var isValid = await _otpService.VerifyOtpAsync(email, code, ct);
            if (!isValid)
                return Result<VerifyCodeResponse>.Failure("Invalid or expired Code.");

            var user = await _unitOfWork.Users.GetByEmailAsync(email, ct);
            if (user == null)
                return Result<VerifyCodeResponse>.Failure("User not found.");

            if (!user.EmailConfirmed)
            {
                user.EmailConfirmed = true;
                user.Approved = true;
                user.UpdatedAt = DateTime.UtcNow;

                await _unitOfWork.Users.UpdateAsync(user, ct);
            }

            var accessToken = _tokenService.GenerateAccessToken(user);
            var refreshToken = _tokenService.GenerateRefreshToken(request.IpAddress);

            user.RefreshTokens ??= new List<RefreshToken>();
            refreshToken.UserId = user.Id;
            user.RefreshTokens.Add(refreshToken);
            user.UpdatedAt = DateTime.UtcNow;

            await _unitOfWork.Users.UpdateAsync(user, ct);
            await _unitOfWork.SaveChangesAsync(ct);

            var accessTokenMinutes = int.TryParse(_configuration["Jwt:AccessTokenExpirationMinutes"], out var minutes)
                ? minutes
                : 60;

            var response = new VerifyCodeResponse(
                UserId: user.Id,
                Email: user.Email ?? string.Empty,
                Username: user.UserName ?? string.Empty,
                AccessToken: accessToken,
                RefreshToken: refreshToken.Token,
                ExpiresAt: DateTime.UtcNow.AddMinutes(accessTokenMinutes)
            );

            return Result<VerifyCodeResponse>.Success(response);
        }
    }
}
