using Geolink.Application.Interfaces;
using Geolink.Infrastructure.Data;
using Geolink.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore.Storage;

namespace Geolink.Infrastructure;

public class UnitOfWork : IUnitOfWork
{
    private readonly GeolinkDbContext _context;
    private IDbContextTransaction? _transaction;

    private IUserRepository? _users;
    private IRefreshTokenRepository? _refreshTokens;
    private IFriendshipRepository? _friendships;
    private IUserLocationRepository? _userLocations;
    private IEventRepository? _events;

    public UnitOfWork(GeolinkDbContext context)
    {
        _context = context;
    }

    public IUserRepository Users => _users ??= new UserRepository(_context);
    public IRefreshTokenRepository RefreshTokens =>
        _refreshTokens ??= new RefreshTokenRepository(_context);
    public IFriendshipRepository Friendships => _friendships ??= new FriendshipRepository(_context);
    public IUserLocationRepository UserLocations => _userLocations ??= new UserLocationRepository(_context);
    public IEventRepository Events => _events ??= new EventRepository(_context);

    public async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        return await _context.SaveChangesAsync(cancellationToken);
    }

    public async Task BeginTransactionAsync(CancellationToken cancellationToken = default)
    {
        _transaction = await _context.Database.BeginTransactionAsync(cancellationToken);
    }

    public async Task CommitTransactionAsync(CancellationToken cancellationToken = default)
    {
        if (_transaction != null)
        {
            await _transaction.CommitAsync(cancellationToken);
            await _transaction.DisposeAsync();
            _transaction = null;
        }
    }

    public async Task RollbackTransactionAsync(CancellationToken cancellationToken = default)
    {
        if (_transaction != null)
        {
            await _transaction.RollbackAsync(cancellationToken);
            await _transaction.DisposeAsync();
            _transaction = null;
        }
    }

    public void Dispose()
    {
        _transaction?.Dispose();
        _context.Dispose();
    }
}
