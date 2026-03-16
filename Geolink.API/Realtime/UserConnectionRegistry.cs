using System.Collections.Concurrent;

namespace Geolink.API.Realtime;

public class UserConnectionRegistry : IUserConnectionRegistry
{
    private readonly ConcurrentDictionary<Guid, ConnectionBucket> _connections = new();

    public bool AddConnection(Guid userId, string connectionId)
    {
        if (userId == Guid.Empty || string.IsNullOrWhiteSpace(connectionId))
            return false;

        var bucket = _connections.GetOrAdd(userId, _ => new ConnectionBucket());

        lock (bucket.Lock)
        {
            bucket.ConnectionIds.Add(connectionId);
            return bucket.ConnectionIds.Count == 1;
        }
    }

    public bool RemoveConnection(Guid userId, string connectionId)
    {
        if (userId == Guid.Empty || string.IsNullOrWhiteSpace(connectionId))
            return false;

        if (!_connections.TryGetValue(userId, out var bucket))
            return false;

        lock (bucket.Lock)
        {
            bucket.ConnectionIds.Remove(connectionId);

            if (bucket.ConnectionIds.Count != 0)
                return false;

            _connections.TryRemove(userId, out _);
            return true;
        }
    }

    public IReadOnlyCollection<string> GetConnections(Guid userId)
    {
        if (!_connections.TryGetValue(userId, out var bucket))
            return Array.Empty<string>();

        lock (bucket.Lock)
        {
            return bucket.ConnectionIds.ToArray();
        }
    }

    public bool IsOnline(Guid userId)
    {
        return GetConnections(userId).Count > 0;
    }

    private sealed class ConnectionBucket
    {
        public object Lock { get; } = new();
        public HashSet<string> ConnectionIds { get; } = new(StringComparer.Ordinal);
    }
}
