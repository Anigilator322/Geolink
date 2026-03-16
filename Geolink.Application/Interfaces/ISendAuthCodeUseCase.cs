using Geolink.Application.Common;
using Geolink.Application.UseCaseContracts;

namespace Geolink.Application.Interfaces
{
    public interface ISendAuthCodeUseCase
    {
        public Task<Result<SendAuthCodeResponse>> ExecuteAsync(SendAuthCodeRequest request, CancellationToken ct);
    }
}
