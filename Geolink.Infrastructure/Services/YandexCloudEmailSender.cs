using System.Text;
using System.Text.Json;
using Geolink.Application.Interfaces;
using Geolink.Infrastructure.Options;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Geolink.Infrastructure.Services;

public class YandexCloudEmailSender : IEmailSender
{
    private readonly HttpClient _httpClient;
    private readonly YandexCloudPostboxOptions _options;
    private readonly ILogger<YandexCloudEmailSender> _logger;

    public YandexCloudEmailSender(
        HttpClient httpClient,
        IOptions<YandexCloudPostboxOptions> options,
        ILogger<YandexCloudEmailSender> logger)
    {
        _httpClient = httpClient;
        _options = options.Value;
        _logger = logger;
    }

    // AWS-compatible Postbox API:
    // POST /v2/email/outbound-emails
    // https://yandex.cloud/ru/docs/postbox/aws-compatible-api/api-ref/send-email
    public async Task SendAsync(string to, string subject, string body, CancellationToken cancellationToken = default)
    {
        if (!_options.Enabled)
            throw new InvalidOperationException("YandexCloudPostbox is disabled.");

        if (string.IsNullOrWhiteSpace(_options.FromEmail))
            throw new InvalidOperationException("YandexCloudPostbox:FromEmail is not configured.");

        var payload = new
        {
            FromEmailAddress = _options.FromEmail,
            Destination = new
            {
                ToAddresses = new[] { to }
            },
            Content = new
            {
                Simple = new
                {
                    Subject = new
                    {
                        Data = subject,
                        Charset = "UTF-8"
                    },
                    Body = new
                    {
                        Text = new
                        {
                            Data = body,
                            Charset = "UTF-8"
                        }
                    }
                }
            }
        };

        using var request = new HttpRequestMessage(
            HttpMethod.Post,
            $"{_options.Endpoint.TrimEnd('/')}/v2/email/outbound-emails");

        request.Content = new StringContent(
            JsonSerializer.Serialize(payload),
            Encoding.UTF8,
            "application/json");

        if (!string.IsNullOrWhiteSpace(_options.IamToken))
        {
            request.Headers.Add("X-YaCloud-SubjectToken", _options.IamToken);
        }
        else
        {
            throw new InvalidOperationException(
                "YandexCloudPostbox auth is not configured. Set IamToken for the current draft implementation, or later add static access key + AWS SigV4 signing.");
        }

        var response = await _httpClient.SendAsync(request, cancellationToken);
        var responseBody = await response.Content.ReadAsStringAsync(cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            _logger.LogError(
                "Yandex Cloud Postbox send failed. Status: {StatusCode}. Body: {Body}",
                (int)response.StatusCode,
                responseBody);

            throw new InvalidOperationException(
                $"Failed to send email via Yandex Cloud Postbox. Status: {(int)response.StatusCode}");
        }
    }
}