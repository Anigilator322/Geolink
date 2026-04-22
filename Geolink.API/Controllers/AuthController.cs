using Geolink.Application.DTOs.Auth;
using Geolink.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Geolink.API.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly IVerifyCodeUseCase _verifyCode;
    private readonly IRefreshTokenUseCase _refreshToken;
    private readonly ISendAuthCodeUseCase _sendAuthCode;
    private readonly ILogger<AuthController> _logger;

    public AuthController(
        ILogger<AuthController> logger,
        IVerifyCodeUseCase verifyCode,
        IRefreshTokenUseCase refreshToken,
        ISendAuthCodeUseCase sendAuthCode)
    {
        _logger = logger;
        _verifyCode = verifyCode;
        _refreshToken = refreshToken;
        _sendAuthCode = sendAuthCode;
    }

    [HttpGet("health")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<IActionResult> Health()
    {
        return Ok(new { message = "Auth API is running" });
    }

    [HttpPost("send-code")]
    [ProducesResponseType(typeof(AuthResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> SendCode([FromBody] SendCodeRequest request, CancellationToken cancellationToken)
    {
        var result = await _sendAuthCode.ExecuteAsync(
            new Application.UseCaseContracts.SendAuthCodeRequest(request.Email), cancellationToken);

        if (!result.IsSuccess)
            return BadRequest(result.Error);

        _logger.LogInformation("User signed in by email for {Email}", request.Email);

        var response = new AuthResponse(
            result.Value!.UserId,
            result.Value.Email,
            result.Value.Username,
            result.Value.AccessToken,
            result.Value.RefreshToken,
            result.Value.ExpiresAt);

        return Ok(response);
    }

    [HttpPost("verify-code")]
    [ProducesResponseType(typeof(AuthResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> VerifyCode([FromBody] VerifyCodeRequest request, CancellationToken cancellationToken)
    {
        var ipAddress = HttpContext.Connection.RemoteIpAddress?.ToString();

        var result = await _verifyCode.ExecuteAsync(new Application.UseCaseContracts.VerifyCodeRequest(
            request.Email,
            request.Code,
            ipAddress),
            cancellationToken);

        if (!result.IsSuccess)
            return BadRequest(result.Error);

        return Ok(result.Value);
    }

    [HttpPost("refresh-token")]
    [ProducesResponseType(typeof(AuthResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> RefreshToken(
        [FromBody] RefreshTokenRequest request,
        CancellationToken cancellationToken)
    {
        var ipAddress = HttpContext.Connection.RemoteIpAddress?.ToString();

        var result = await _refreshToken.ExecuteAsync(
            new Application.UseCaseContracts.RefreshTokenRequest(
                request.RefreshToken,
                ipAddress),
            cancellationToken);

        if (!result.IsSuccess || result.Value == null)
        {
            return StatusCode(
                result.StatusCode ?? StatusCodes.Status400BadRequest,
                result.Error);
        }

        var response = new AuthResponse(
            result.Value.UserId,
            result.Value.Email,
            result.Value.Username,
            result.Value.AccessToken,
            result.Value.RefreshToken,
            result.Value.ExpiresAt);

        return Ok(response);
    }
}
