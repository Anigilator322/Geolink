namespace Geolink.Application.Interfaces;

public interface IEmailOtpService
{
    /// <summary>Генерирует 6-значный OTP, кэширует его и отправляет на данный электронный адрес.</summary>
    Task SendOtpAsync(string email, CancellationToken cancellationToken = default);

    /// <summary>Проверяет код. Возвращает true и удаляет код при успехе.</summary>
    Task<bool> VerifyOtpAsync(string email, string code, CancellationToken cancellationToken = default);
}
