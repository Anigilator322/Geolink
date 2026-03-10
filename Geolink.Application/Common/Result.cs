namespace Geolink.Application.Common;

public class Result<T>
{
    public bool IsSuccess { get; }
    public T? Value { get; }
    public string? Error { get; }
    public int? StatusCode { get; }

    private Result(bool isSuccess, T? value, string? error, int? statusCode)
    {
        IsSuccess = isSuccess;
        Value = value;
        Error = error;
        StatusCode = statusCode;
    }

    public static Result<T> Success(T value) => new(true, value, null, null);
    public static Result<T> Failure(string error, int statusCode = 400) => new(false, default, error, statusCode);
    public static Result<T> NotFound(string error = "Ресурс не найден") => new(false, default, error, 404);
    public static Result<T> Unauthorized(string error = "Не авторизован") => new(false, default, error, 401);
    public static Result<T> Forbidden(string error = "Запрещено") => new(false, default, error, 403);
}

public class Result
{
    public bool IsSuccess { get; }
    public string? Error { get; }
    public int? StatusCode { get; }

    private Result(bool isSuccess, string? error, int? statusCode)
    {
        IsSuccess = isSuccess;
        Error = error;
        StatusCode = statusCode;
    }

    public static Result Success() => new(true, null, null);
    public static Result Failure(string error, int statusCode = 400) => new(false, error, statusCode);
    public static Result NotFound(string error = "Ресурс не найден") => new(false, error, 404);
    public static Result Unauthorized(string error = "Не авторизован") => new(false, error, 401);
    public static Result Forbidden(string error = "Запрещено") => new(false, error, 403);
}
