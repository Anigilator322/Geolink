using Geolink.Application.DTOs.Auth;
using Geolink.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Geolink.API.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly IVerifyCodeUseCase _verifyCode;
    private readonly ISendAuthCodeUseCase _sendAuthCode;
    private readonly ILogger<AuthController> _logger;

    public AuthController(
        ILogger<AuthController> logger, IVerifyCodeUseCase verifyCode, ISendAuthCodeUseCase sendAuthCode)
    {
        _logger = logger;
        _verifyCode = verifyCode;
        _sendAuthCode = sendAuthCode;
    }

    [HttpPost("send-code")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> SendCode([FromBody] SendCodeRequest request, CancellationToken cancellationToken)
    {
        var result = await _sendAuthCode.ExecuteAsync(
            new Application.UseCaseContracts.SendAuthCodeRequest(request.Email), cancellationToken);

        if (!result.IsSuccess)
            return BadRequest(result.Error);

        _logger.LogInformation("OTP code requested for {Email}", request.Email);

        return Ok(new { message = "Code sent" });
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
}