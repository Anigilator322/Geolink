namespace Geolink.API.Realtime;

public interface IUserConnectionRegistry
{
    bool AddConnection(Guid userId, string connectionId);
    bool RemoveConnection(Guid userId, string connectionId);
    IReadOnlyCollection<string> GetConnections(Guid userId);
    bool IsOnline(Guid userId);
}
