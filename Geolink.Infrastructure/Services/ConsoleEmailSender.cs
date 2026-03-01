using Geolink.Application.Interfaces;
using Microsoft.Extensions.Logging;

namespace Geolink.Infrastructure.Services;

/// <summary>
/// Development stub — prints emails to the console instead of sending them.
/// Replace with a real implementation (SMTP/SendGrid/etc.) for production.
/// </summary>
public class ConsoleEmailSender(ILogger<ConsoleEmailSender> logger) : IEmailSender
{
    public Task SendAsync(string to, string subject, string body, CancellationToken cancellationToken = default)
    {
        logger.LogInformation(
            "[DEV EMAIL] To: {To} | Subject: {Subject}\n{Body}",
            to, subject, body);

        return Task.CompletedTask;
    }
}
