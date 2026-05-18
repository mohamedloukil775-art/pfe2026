using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PadelChampionship.Api.Controllers;
using PadelChampionship.Api.Data;
using PadelChampionship.Api.Dtos;
using PadelChampionship.Api.Models;

namespace PadelChampionship.Api.Tests;

public class BusinessRulesTests
{
    private static ApplicationDbContext CreateDbContext()
    {
        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        return new ApplicationDbContext(options);
    }

    [Fact]
    public async Task Teams_Create_AllowsPlayersWithDifferentLevels()
    {
        await using var db = CreateDbContext();
        db.Users.AddRange(
            new User { Id = 1, Nom = "A", Email = "a@t.com", MotDePasseHash = "x", Role = UserRole.Joueur, Niveau = 2 },
            new User { Id = 2, Nom = "B", Email = "b@t.com", MotDePasseHash = "x", Role = UserRole.Joueur, Niveau = 7 }
        );
        await db.SaveChangesAsync();

        var controller = new TeamsController(db);
        var result = await controller.Create(new CreateTeamRequest("Team X", [1, 2]));

        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        Assert.NotNull(okResult.Value);

        var team = await db.Teams.Include(t => t.Players).ThenInclude(tp => tp.User).FirstAsync();
        Assert.Equal(2, team.Players.Count);
    }

    [Fact]
    public async Task Matches_SubmitScore_After24h_SetsForfeit()
    {
        await using var db = CreateDbContext();
        db.Teams.AddRange(
            new Team { Id = 1, NomEquipe = "T1" },
            new Team { Id = 2, NomEquipe = "T2" }
        );
        db.Matches.Add(new ChampionshipMatch
        {
            Id = 11,
            Equipe1Id = 1,
            Equipe2Id = 2,
            Date = DateTime.UtcNow.AddHours(-25),
            Terrain = "Court 1",
            Statut = MatchStatus.Programme
        });
        await db.SaveChangesAsync();

        var controller = new MatchesController(db);
        var result = await controller.SubmitScore(11, new SubmitScoreRequest(1, 6, 3));

        var badRequest = Assert.IsType<BadRequestObjectResult>(result);
        Assert.Contains("forfait", badRequest.Value?.ToString(), StringComparison.OrdinalIgnoreCase);

        var match = await db.Matches.FirstAsync(m => m.Id == 11);
        Assert.Equal(MatchStatus.Forfait, match.Statut);
    }

    [Fact]
    public async Task Matches_ValidateScore_RebuildsParticipations_WithExpectedPoints()
    {
        await using var db = CreateDbContext();

        db.Users.AddRange(
            new User { Id = 1, Nom = "P1", Email = "p1@t.com", MotDePasseHash = "x", Role = UserRole.Joueur, Niveau = 5 },
            new User { Id = 2, Nom = "P2", Email = "p2@t.com", MotDePasseHash = "x", Role = UserRole.Joueur, Niveau = 5 },
            new User { Id = 3, Nom = "P3", Email = "p3@t.com", MotDePasseHash = "x", Role = UserRole.Joueur, Niveau = 5 },
            new User { Id = 4, Nom = "P4", Email = "p4@t.com", MotDePasseHash = "x", Role = UserRole.Joueur, Niveau = 5 }
        );

        db.Teams.AddRange(
            new Team { Id = 10, NomEquipe = "Alpha" },
            new Team { Id = 20, NomEquipe = "Beta" }
        );

        db.TeamPlayers.AddRange(
            new TeamPlayer { TeamId = 10, UserId = 1 },
            new TeamPlayer { TeamId = 10, UserId = 2 },
            new TeamPlayer { TeamId = 20, UserId = 3 },
            new TeamPlayer { TeamId = 20, UserId = 4 }
        );

        db.Matches.Add(new ChampionshipMatch
        {
            Id = 50,
            Equipe1Id = 10,
            Equipe2Id = 20,
            Date = DateTime.UtcNow,
            Terrain = "Court 2",
            Statut = MatchStatus.Programme
        });

        await db.SaveChangesAsync();

        var controller = new MatchesController(db);
        var result = await controller.ValidateScore(50, new ValidateScoreRequest(6, 3));

        Assert.IsType<OkResult>(result);

        var participations = await db.Participations
            .Where(p => p.MatchId == 50)
            .OrderBy(p => p.JoueurId)
            .ToListAsync();

        Assert.Equal(4, participations.Count);
        Assert.Equal(3, participations.Single(p => p.JoueurId == 1).PointsObtenus);
        Assert.Equal(3, participations.Single(p => p.JoueurId == 2).PointsObtenus);
        Assert.Equal(1, participations.Single(p => p.JoueurId == 3).PointsObtenus);
        Assert.Equal(1, participations.Single(p => p.JoueurId == 4).PointsObtenus);
    }

    [Fact]
    public async Task Players_UpdateLevel_AddsTechnicalTest_AndUpdatesPlayerLevel()
    {
        await using var db = CreateDbContext();
        db.Users.Add(new User
        {
            Id = 99,
            Nom = "Player",
            Email = "player@t.com",
            MotDePasseHash = "x",
            Role = UserRole.Joueur,
            Niveau = 4
        });
        await db.SaveChangesAsync();

        var controller = new PlayersController(db);
        var result = await controller.UpdateLevel(99, new UpdatePlayerLevelRequest(6, 90));

        Assert.IsType<NoContentResult>(result);

        var player = await db.Users.FirstAsync(u => u.Id == 99);
        Assert.Equal(6, player.Niveau);

        var test = await db.TechnicalTests.SingleAsync(t => t.JoueurId == 99);
        Assert.Equal(90, test.ScoreTest);
        Assert.Equal(6, test.NiveauAttribue);
    }

    [Fact]
    public async Task Players_GetLevelHistory_ReturnsDescendingDates_ForAuthorizedUser()
    {
        await using var db = CreateDbContext();
        db.Users.Add(new User
        {
            Id = 7,
            Nom = "Player7",
            Email = "p7@t.com",
            MotDePasseHash = "x",
            Role = UserRole.Joueur,
            Niveau = 5
        });

        db.TechnicalTests.AddRange(
            new TechnicalTest
            {
                Id = 1,
                JoueurId = 7,
                DateTest = new DateTime(2026, 3, 1, 10, 0, 0, DateTimeKind.Utc),
                ScoreTest = 70,
                NiveauAttribue = 5
            },
            new TechnicalTest
            {
                Id = 2,
                JoueurId = 7,
                DateTest = new DateTime(2026, 3, 5, 10, 0, 0, DateTimeKind.Utc),
                ScoreTest = 84,
                NiveauAttribue = 6
            }
        );
        await db.SaveChangesAsync();

        var controller = new PlayersController(db)
        {
            ControllerContext = new ControllerContext
            {
                HttpContext = new DefaultHttpContext
                {
                    User = new ClaimsPrincipal(
                        new ClaimsIdentity(
                            [
                                new Claim(ClaimTypes.NameIdentifier, "7"),
                                new Claim(ClaimTypes.Role, "Joueur")
                            ],
                            "test"
                        )
                    )
                }
            }
        };

        var action = await controller.GetLevelHistory(7);
        var ok = Assert.IsType<OkObjectResult>(action.Result);
        var history = Assert.IsAssignableFrom<List<PlayerLevelHistoryResponse>>(ok.Value);

        Assert.Equal(2, history.Count);
        Assert.True(history[0].DateTest >= history[1].DateTest);
        Assert.Equal(6, history[0].NiveauAttribue);
    }
}
