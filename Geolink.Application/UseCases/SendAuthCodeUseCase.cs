using Geolink.Application.Common;
using Geolink.Application.Interfaces;
using Geolink.Application.UseCaseContracts;
using Geolink.Domain.Entities;
using Microsoft.AspNetCore.Identity;
using System.Threading;

namespace Geolink.Application.UseCases
{
    public class SendAuthCodeUseCase : UseCaseBase<SendAuthCodeResponse, SendAuthCodeRequest>, ISendAuthCodeUseCase
    {
        private readonly IEmailOtpService _emailOtpService;
        private readonly IEmailSender _emailSender;
        private readonly IUnitOfWork _unitOfWork;
        private readonly IUserService _userService;
        public SendAuthCodeUseCase(IEmailOtpService emailOtp, IEmailSender emailSender,IUnitOfWork unitOfWork, IUserService userService)
        {
            _emailOtpService = emailOtp;
            _unitOfWork = unitOfWork;
            _emailSender = emailSender;
            _userService = userService;
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

            await _emailOtpService.SendOtpAsync(emailTrimmed, ct);
            return Result<SendAuthCodeResponse>.Success(new SendAuthCodeResponse(emailTrimmed));
        }
    }
}
