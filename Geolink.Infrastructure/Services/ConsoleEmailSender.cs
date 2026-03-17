using Geolink.Application.Interfaces;
using Microsoft.Extensions.Logging;

namespace Geolink.Infrastructure.Services;

public class ConsoleEmailSender(ILogger<ConsoleEmailSender> logger) : IEmailSender
{
    public Task SendAsync(string to, string subject, string body, CancellationToken cancellationToken = default)
    {
        logger.LogWarning(
            "[DEV EMAIL] To: {To} | Subject: {Subject}\n{Body}",
            to, subject, body);

        return Task.CompletedTask;
    }
}
