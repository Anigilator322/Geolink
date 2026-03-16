using Geolink.Application.Common;

namespace Geolink.Application.UseCases
{
    public abstract class UseCaseBase<Response, Request>
    {
        public abstract Task<Result<Response>> ExecuteAsync(Request request, CancellationToken ct);
    }
}
