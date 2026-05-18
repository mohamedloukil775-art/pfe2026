using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using PadelChampionship.Api.Data;
using PadelChampionship.Api.Models;
using PadelChampionship.Api.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var useInMemory = builder.Configuration.GetValue<bool>("UseInMemoryDatabase");
if (useInMemory)
{
    builder.Services.AddDbContext<ApplicationDbContext>(opt => opt.UseInMemoryDatabase("PadelDb"));
}
else
{
    var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
                           ?? throw new InvalidOperationException("Missing DB connection string");
    builder.Services.AddDbContext<ApplicationDbContext>(opt =>
        opt.UseMySql(connectionString, ServerVersion.AutoDetect(connectionString)));
}
// Use in-memory database for development
builder.Services.AddDbContext<ApplicationDbContext>(opt => opt.UseInMemoryDatabase("PadelDb"));

builder.Services.AddScoped<IJwtTokenService, JwtTokenService>();

var jwtKey = builder.Configuration["Jwt:Key"] ?? throw new InvalidOperationException("Jwt key missing");
var signingKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
}).AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"],
        ValidAudience = builder.Configuration["Jwt:Audience"],
        IssuerSigningKey = signingKey,
        ValidateLifetime = true,
        ClockSkew = TimeSpan.FromMinutes(2)
    };
});

builder.Services.AddAuthorization();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

    if (db.Database.IsRelational())
    {
        await db.Database.MigrateAsync();
    }
    else
    {
        await db.Database.EnsureCreatedAsync();
    }

    if (!db.Users.Any())
    {
        var club = new Club { Nom = "Padel Elite", Localisation = "Tunis" };
        db.Clubs.Add(club);

        var admin = new User
        {
            Nom = "Admin Club",
            Email = "admin@padel.com",
            MotDePasseHash = BCrypt.Net.BCrypt.HashPassword("Admin123!"),
            Role = UserRole.Admin,
            Niveau = 10,
            Statut = UserStatus.Actif,
            Club = club
        };

        var ali = new User
        {
            Nom = "Ali Ben",
            Email = "ali@padel.com",
            MotDePasseHash = BCrypt.Net.BCrypt.HashPassword("Player123!"),
            Role = UserRole.Joueur,
            Niveau = 5,
            Statut = UserStatus.Actif,
            Club = club
        };

        var sara = new User
        {
            Nom = "Sara M",
            Email = "sara@padel.com",
            MotDePasseHash = BCrypt.Net.BCrypt.HashPassword("Player123!"),
            Role = UserRole.Joueur,
            Niveau = 6,
            Statut = UserStatus.Actif,
            Club = club
        };

        var yassine = new User
        {
            Nom = "Yassine K",
            Email = "yassine@padel.com",
            MotDePasseHash = BCrypt.Net.BCrypt.HashPassword("Player123!"),
            Role = UserRole.Joueur,
            Niveau = 4,
            Statut = UserStatus.Actif,
            Club = club
        };

        var leila = new User
        {
            Nom = "Leila T",
            Email = "leila@padel.com",
            MotDePasseHash = BCrypt.Net.BCrypt.HashPassword("Player123!"),
            Role = UserRole.Joueur,
            Niveau = 5,
            Statut = UserStatus.Actif,
            Club = club
        };

        db.Users.AddRange(admin, ali, sara, yassine, leila);

        db.SaveChanges();

        var teamA = new Team { NomEquipe = "Eagles" };
        var teamB = new Team { NomEquipe = "Falcons" };
        db.Teams.AddRange(teamA, teamB);
        db.SaveChanges();

        db.TeamPlayers.AddRange(
            new TeamPlayer { TeamId = teamA.Id, UserId = ali.Id },
            new TeamPlayer { TeamId = teamA.Id, UserId = yassine.Id },
            new TeamPlayer { TeamId = teamB.Id, UserId = sara.Id },
            new TeamPlayer { TeamId = teamB.Id, UserId = leila.Id }
        );

        db.Matches.AddRange(
            new ChampionshipMatch
            {
                Date = DateTime.UtcNow.AddHours(3),
                Terrain = "Terrain Central",
                Equipe1Id = teamA.Id,
                Equipe2Id = teamB.Id,
                Statut = MatchStatus.Programme
            },
            new ChampionshipMatch
            {
                Date = DateTime.UtcNow.AddDays(-1),
                Terrain = "Terrain 2",
                Equipe1Id = teamA.Id,
                Equipe2Id = teamB.Id,
                ScoreEquipe1 = 2,
                ScoreEquipe2 = 1,
                Statut = MatchStatus.ResultatSaisi
            }
        );

        db.SaveChanges();
    }
}

app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.Run();
