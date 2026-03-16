using Geolink.Application.Common;
using Geolink.Application.UseCaseContracts;

namespace Geolink.Application.Interfaces
{
    public interface IVerifyCodeUseCase
    {
        public Task<Result<VerifyCodeResponse>> ExecuteAsync(VerifyCodeRequest request, CancellationToken ct);
    }
}
