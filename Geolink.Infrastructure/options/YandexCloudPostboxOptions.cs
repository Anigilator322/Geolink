namespace Geolink.Infrastructure.Options;

public class YandexCloudPostboxOptions
{
    public const string SectionName = "YandexCloudPostbox";

    public bool Enabled { get; set; }
    public string Endpoint { get; set; } = "https://postbox.cloud.yandex.net";
    public string FromEmail { get; set; } = string.Empty;

    //через IAM token
    public string? IamToken { get; set; }

    /* static access key + SigV4
    
    public string? AccessKeyId { get; set; }
    public string? SecretAccessKey { get; set; }
    public string? Region { get; set; } = "ru-central1";
    */
}