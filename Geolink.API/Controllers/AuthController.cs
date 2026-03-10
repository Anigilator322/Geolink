using Geolink.Application.Interfaces;
using Geolink.Domain.Entities;
using Microsoft.AspNetCore.Mvc;

namespace Geolink.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ITokenService _tokenService;
    private readonly ILogger<AuthController> _logger;

    private const string DevOTP = "123456";

    public AuthController(
        IUnitOfWork unitOfWork,
        ITokenService tokenService,
        ILogger<AuthController> logger)
    {
        _unitOfWork = unitOfWork;
        _tokenService = tokenService;
        _logger = logger;
    }

    /// <summary>
    /// Отправить OTP на email (mock - выводит в консоль)
    /// </summary>
    [HttpPost("send-code")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public IActionResult SendCode([FromBody] SendCodeRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Email))
            return BadRequest("Email is required.");

        _logger.LogInformation("[DEV] OTP for {Email}: {Code}", request.Email, DevOTP);
        Console.WriteLine($"[DEV OTP] {request.Email}: {DevOTP}");

        return Ok(new { message = "Code sent" });
    }

    /// <summary>
    /// Проверить OTP и аутентифицировать пользователя
    /// </summary>
    [HttpPost("verify-code")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> VerifyCode([FromBody] VerifyCodeRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Code))
            return BadRequest("Email and code are required.");

        if (request.Code != DevOTP)
            return BadRequest("Invalid code.");

        try
        {
            var user = await _unitOfWork.Users.GetByEmailAsync(request.Email);
            if (user == null)
            {
                user = new User
                {
                    Id = Guid.NewGuid(),
                    Email = request.Email,
                    NormalizedEmail = request.Email.ToUpper(),
                    UserName = request.Email.Split('@')[0],
                    NormalizedUserName = request.Email.Split('@')[0].ToUpper(),
                    EmailConfirmed = true,
                    CreatedAt = DateTime.UtcNow,
                    Approved = true
                };

                await _unitOfWork.Users.AddAsync(user);
                await _unitOfWork.SaveChangesAsync();
                _logger.LogInformation("Created new user: {Email}", request.Email);
            }

            var accessToken = _tokenService.GenerateAccessToken(user);
            var refreshToken = _tokenService.GenerateRefreshToken(HttpContext.Connection.RemoteIpAddress?.ToString());

            user.RefreshTokens ??= new List<RefreshToken>();
            user.RefreshTokens.Add(refreshToken);

            await _unitOfWork.Users.UpdateAsync(user);
            await _unitOfWork.SaveChangesAsync();

            return Ok(new
            {
                accessToken,
                refreshToken = refreshToken.Token,
                expiresIn = 3600
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during verify-code");
            return BadRequest("Authentication failed.");
        }
    }

    public record SendCodeRequest(string Email);
    public record VerifyCodeRequest(string Email, string Code);
}