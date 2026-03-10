using Geolink.Application.Interfaces;
using StackExchange.Redis;

namespace Geolink.Infrastructure.Services;

public class EmailOtpService(IConnectionMultiplexer redis, IEmailSender emailSender) : IEmailOtpService
{
    private readonly IDatabase _db = redis.GetDatabase();

    private const string KeyPrefix = "otp:";
    private static readonly TimeSpan Ttl = TimeSpan.FromMinutes(5);

    public async Task SendOtpAsync(string email, CancellationToken cancellationToken = default)
    {
        var code = Random.Shared.Next(100_000, 999_999).ToString();
        var key = BuildKey(email);

        await _db.StringSetAsync(key, code, Ttl);

        await emailSender.SendAsync(
            to: email,
            subject: "Ваш код входа в Geolink",
            body: $"Код для входа: {code}\n\nКод действителен 5 минут.",
            cancellationToken: cancellationToken);
    }

    public async Task<bool> VerifyOtpAsync(string email, string code, CancellationToken cancellationToken = default)
    {
        var key = BuildKey(email);
        var stored = await _db.StringGetAsync(key);

        if (!stored.HasValue || stored != code)
            return false;

        await _db.KeyDeleteAsync(key); // one-time use
        return true;
    }

    private static string BuildKey(string email) => $"{KeyPrefix}{email.ToLowerInvariant()}";
}
