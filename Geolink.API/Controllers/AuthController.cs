using Geolink.Application.DTOs.Auth;
using Geolink.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Geolink.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly ILogger<AuthController> _logger;

    public AuthController(
        IAuthService authService,
        ILogger<AuthController> logger)
    {
        _authService = authService;
        _logger = logger;
    }

    [HttpPost("send-code")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> SendCode([FromBody] SendCodeRequest request, CancellationToken cancellationToken)
    {
        var result = await _authService.SendCodeAsync(request.Email, cancellationToken);

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

        var result = await _authService.VerifyCodeAsync(
            request.Email,
            request.Code,
            ipAddress,
            cancellationToken);

        if (!result.IsSuccess)
            return BadRequest(result.Error);

        return Ok(result.Value);
    }
}