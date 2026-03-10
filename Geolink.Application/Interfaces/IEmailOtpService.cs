namespace Geolink.Application.Interfaces;

public interface IEmailOtpService
{
    /// <summary>Generates a 6-digit OTP, caches it, and sends it to the given email.</summary>
    Task SendOtpAsync(string email, CancellationToken cancellationToken = default);

    /// <summary>Validates the code. Returns true and removes the code on success.</summary>
    Task<bool> VerifyOtpAsync(string email, string code, CancellationToken cancellationToken = default);
}
