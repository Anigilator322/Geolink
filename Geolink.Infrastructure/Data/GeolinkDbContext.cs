using Geolink.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace Geolink.Infrastructure.Data;

public class GeolinkDbContext : DbContext
{
    public GeolinkDbContext(DbContextOptions<GeolinkDbContext> options) : base(options)
    {
    }

    public DbSet<User> Users => Set<User>();
    public DbSet<UserLocation> UserLocations => Set<UserLocation>();
    public DbSet<Friendship> Friendships => Set<Friendship>();
    public DbSet<Event> Events => Set<Event>();
    public DbSet<EventParticipant> EventParticipants => Set<EventParticipant>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // User configuration
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.Email).IsUnique();
            entity.HasIndex(e => e.Username).IsUnique();
            entity.Property(e => e.Email).HasMaxLength(256).IsRequired();
            entity.Property(e => e.Username).HasMaxLength(50).IsRequired();
            entity.Property(e => e.PasswordHash).IsRequired();
            entity.Property(e => e.DisplayName).HasMaxLength(100);
            entity.Property(e => e.AvatarUrl).HasMaxLength(500);
            entity.Property(e => e.Bio).HasMaxLength(500);
        });

        // UserLocation configuration
        modelBuilder.Entity<UserLocation>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.UserId).IsUnique();
            entity.HasOne(e => e.User)
                .WithOne(u => u.CurrentLocation)
                .HasForeignKey<UserLocation>(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // Friendship configuration
        modelBuilder.Entity<Friendship>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => new { e.RequesterId, e.AddresseeId }).IsUnique();
            
            entity.HasOne(e => e.Requester)
                .WithMany(u => u.SentFriendRequests)
                .HasForeignKey(e => e.RequesterId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(e => e.Addressee)
                .WithMany(u => u.ReceivedFriendRequests)
                .HasForeignKey(e => e.AddresseeId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // Event configuration
        modelBuilder.Entity<Event>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.CreatorId);
            entity.HasIndex(e => e.StartsAt);
            entity.Property(e => e.Title).HasMaxLength(200).IsRequired();
            entity.Property(e => e.Description).HasMaxLength(2000);
            entity.Property(e => e.Address).HasMaxLength(500);
            entity.Property(e => e.ImageUrl).HasMaxLength(500);
            
            entity.HasOne(e => e.Creator)
                .WithMany(u => u.CreatedEvents)
                .HasForeignKey(e => e.CreatorId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // EventParticipant configuration
        modelBuilder.Entity<EventParticipant>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => new { e.EventId, e.UserId }).IsUnique();
            
            entity.HasOne(e => e.Event)
                .WithMany(ev => ev.Participants)
                .HasForeignKey(e => e.EventId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(e => e.User)
                .WithMany(u => u.EventParticipations)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // RefreshToken configuration
        modelBuilder.Entity<RefreshToken>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.Token).IsUnique();
            entity.HasIndex(e => e.UserId);
            entity.Property(e => e.Token).HasMaxLength(500).IsRequired();
            entity.Property(e => e.CreatedByIp).HasMaxLength(50);
            entity.Property(e => e.RevokedByIp).HasMaxLength(50);
            entity.Property(e => e.ReplacedByToken).HasMaxLength(500);
            
            entity.HasOne(e => e.User)
                .WithMany(u => u.RefreshTokens)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });
    }

    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        foreach (var entry in ChangeTracker.Entries())
        {
            if (entry.Entity is Domain.Common.BaseEntity entity)
            {
                switch (entry.State)
                {
                    case EntityState.Added:
                        entity.CreatedAt = DateTime.UtcNow;
                        if (entity.Id == Guid.Empty)
                            entity.Id = Guid.NewGuid();
                        break;
                    case EntityState.Modified:
                        entity.UpdatedAt = DateTime.UtcNow;
                        break;
                }
            }
        }

        return base.SaveChangesAsync(cancellationToken);
    }
}
