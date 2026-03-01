using Geolink.Domain.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace Geolink.Infrastructure.Data;

public class GeolinkDbContext : IdentityDbContext<User, IdentityRole<Guid>, Guid>
{
    public GeolinkDbContext(DbContextOptions<GeolinkDbContext> options) : base(options)
    {
    }

    // Users DbSet is inherited from IdentityDbContext
    public DbSet<UserLocation> UserLocations => Set<UserLocation>();
    public DbSet<UserSettings> UserSettings => Set<UserSettings>();
    public DbSet<Friendship> Friendships => Set<Friendship>();
    public DbSet<Event> Events => Set<Event>();
    public DbSet<EventSettings> EventSettings => Set<EventSettings>();
    public DbSet<EventParticipant> EventParticipants => Set<EventParticipant>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Identity sets up AspNetUsers table with all built-in indexes and constraints
        base.OnModelCreating(modelBuilder);

        // User — only our custom columns; Identity handles the rest
        modelBuilder.Entity<User>(entity =>
        {
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

        // UserSettings configuration
        modelBuilder.Entity<UserSettings>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.UserId).IsUnique();
            entity.Property(e => e.LocationRefreshTimingSeconds).IsRequired();

            entity.HasOne(e => e.User)
                .WithOne(u => u.Settings)
                .HasForeignKey<UserSettings>(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            // Many-to-many: UserSettings.HideFrom ↔ User (users hidden from location sharing)
            entity.HasMany(e => e.HideFrom)
                .WithMany()
                .UsingEntity(j => j.ToTable("UserSettingsHideFrom"));
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
            entity.Property(e => e.Title).HasMaxLength(200).IsRequired();

            entity.HasOne(e => e.Creator)
                .WithMany(u => u.CreatedEvents)
                .HasForeignKey(e => e.CreatorId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // EventSettings configuration
        modelBuilder.Entity<EventSettings>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.EventId).IsUnique();
            entity.HasIndex(e => e.StartsAt);
            entity.Property(e => e.Description).HasMaxLength(2000);
            entity.Property(e => e.Address).HasMaxLength(500);
            entity.Property(e => e.PreviewUrl).HasMaxLength(500);

            entity.HasOne(e => e.Event)
                .WithOne(ev => ev.EventSettings)
                .HasForeignKey<EventSettings>(e => e.EventId)
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
        var now = DateTime.UtcNow;

        foreach (var entry in ChangeTracker.Entries())
        {
            if (entry.Entity is Domain.Common.BaseEntity baseEntity)
            {
                switch (entry.State)
                {
                    case EntityState.Added:
                        baseEntity.CreatedAt = now;
                        if (baseEntity.Id == Guid.Empty)
                            baseEntity.Id = Guid.NewGuid();
                        break;
                    case EntityState.Modified:
                        baseEntity.UpdatedAt = now;
                        break;
                }
            }
            else if (entry.Entity is User user)
            {
                switch (entry.State)
                {
                    case EntityState.Added:
                        user.CreatedAt = now;
                        break;
                    case EntityState.Modified:
                        user.UpdatedAt = now;
                        break;
                }
            }
        }

        return base.SaveChangesAsync(cancellationToken);
    }
}
