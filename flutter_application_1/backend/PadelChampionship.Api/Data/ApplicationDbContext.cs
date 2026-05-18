using Microsoft.EntityFrameworkCore;
using PadelChampionship.Api.Models;

namespace PadelChampionship.Api.Data;

public class ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : DbContext(options)
{
    public DbSet<User> Users => Set<User>();
    public DbSet<Club> Clubs => Set<Club>();
    public DbSet<Team> Teams => Set<Team>();
    public DbSet<TeamPlayer> TeamPlayers => Set<TeamPlayer>();
    public DbSet<ChampionshipMatch> Matches => Set<ChampionshipMatch>();
    public DbSet<Participation> Participations => Set<Participation>();
    public DbSet<TechnicalTest> TechnicalTests => Set<TechnicalTest>();
    public DbSet<Reward> Rewards => Set<Reward>();
    public DbSet<Tournament> Tournaments => Set<Tournament>();
    public DbSet<TournamentMatch> TournamentMatches => Set<TournamentMatch>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<User>()
            .HasIndex(u => u.Email)
            .IsUnique();

        modelBuilder.Entity<TeamPlayer>()
            .HasKey(tp => new { tp.TeamId, tp.UserId });

        modelBuilder.Entity<TeamPlayer>()
            .HasOne(tp => tp.Team)
            .WithMany(t => t.Players)
            .HasForeignKey(tp => tp.TeamId);

        modelBuilder.Entity<TeamPlayer>()
            .HasOne(tp => tp.User)
            .WithMany(u => u.TeamMemberships)
            .HasForeignKey(tp => tp.UserId);

        modelBuilder.Entity<ChampionshipMatch>()
            .HasOne(m => m.Equipe1)
            .WithMany()
            .HasForeignKey(m => m.Equipe1Id)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<ChampionshipMatch>()
            .HasOne(m => m.Equipe2)
            .WithMany()
            .HasForeignKey(m => m.Equipe2Id)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
