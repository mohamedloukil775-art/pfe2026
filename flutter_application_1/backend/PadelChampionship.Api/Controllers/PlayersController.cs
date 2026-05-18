using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using PadelChampionship.Api.Data;
using PadelChampionship.Api.Dtos;
using PadelChampionship.Api.Models;

namespace PadelChampionship.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class PlayersController(ApplicationDbContext db) : ControllerBase
{
    [Authorize(Roles = "Admin")]
    [HttpGet]
    public async Task<ActionResult<List<PlayerResponse>>> GetAll()
    {
        var players = await db.Users
            .Where(u => u.Role == UserRole.Joueur)
            .Select(u => new PlayerResponse(
                u.Id,
                u.Nom,
                u.Email,
                u.Niveau,
                MapCategory(u.Niveau),
                u.Statut.ToString(),
                u.ClubId))
            .ToListAsync();

        return Ok(players);
    }

    [Authorize(Roles = "Admin")]
    [HttpPost]
    public async Task<ActionResult<PlayerResponse>> Create([FromBody] CreatePlayerRequest request)
    {
        var exists = await db.Users.AnyAsync(u => u.Email == request.Email);
        if (exists)
        {
            return Conflict("Email déjà utilisé.");
        }

        if (request.Niveau is < 1 or > 10)
        {
            return BadRequest("Le niveau doit être entre 1 et 10.");
        }

        var player = new User
        {
            Nom = request.Nom,
            Email = request.Email,
            MotDePasseHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
            Role = UserRole.Joueur,
            Niveau = request.Niveau,
            Statut = UserStatus.Actif,
            ClubId = request.ClubId
        };

        db.Users.Add(player);
        await db.SaveChangesAsync();

        return CreatedAtAction(nameof(GetAll), new
        {
            id = player.Id
        }, new PlayerResponse(
            player.Id,
            player.Nom,
            player.Email,
            player.Niveau,
            MapCategory(player.Niveau),
            player.Statut.ToString(),
            player.ClubId));
    }

    [Authorize(Roles = "Admin")]
    [HttpPut("{id:int}/level")]
    public async Task<IActionResult> UpdateLevel(int id, [FromBody] UpdatePlayerLevelRequest request)
    {
        var player = await db.Users.FirstOrDefaultAsync(u => u.Id == id && u.Role == UserRole.Joueur);
        if (player is null)
        {
            return NotFound();
        }

        if (request.Niveau is < 1 or > 10)
        {
            return BadRequest("Le niveau doit être entre 1 et 10.");
        }

        player.Niveau = request.Niveau;
        db.TechnicalTests.Add(new TechnicalTest
        {
            JoueurId = player.Id,
            DateTest = DateTime.UtcNow,
            ScoreTest = request.ScoreTest,
            NiveauAttribue = request.Niveau
        });

        await db.SaveChangesAsync();
        return NoContent();
    }

    [Authorize(Roles = "Admin")]
    [HttpPut("{id:int}/block")]
    public async Task<IActionResult> Block(int id)
    {
        var player = await db.Users.FirstOrDefaultAsync(u => u.Id == id && u.Role == UserRole.Joueur);
        if (player is null)
        {
            return NotFound();
        }

        player.Statut = UserStatus.Bloque;
        await db.SaveChangesAsync();
        return NoContent();
    }

    [Authorize(Roles = "Admin")]
    [HttpPut("{id:int}/unblock")]
    public async Task<IActionResult> Unblock(int id)
    {
        var player = await db.Users.FirstOrDefaultAsync(u => u.Id == id && u.Role == UserRole.Joueur);
        if (player is null)
        {
            return NotFound();
        }

        player.Statut = UserStatus.Actif;
        await db.SaveChangesAsync();
        return NoContent();
    }

    [Authorize(Roles = "Admin")]
    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var player = await db.Users.FirstOrDefaultAsync(u => u.Id == id && u.Role == UserRole.Joueur);
        if (player is null)
        {
            return NotFound();
        }

        db.Users.Remove(player);
        await db.SaveChangesAsync();
        return NoContent();
    }

    [Authorize]
    [HttpGet("{id:int}/stats")]
    public async Task<ActionResult<PlayerStatsResponse>> GetStats(int id)
    {
        var currentUserIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        var currentRole = User.FindFirst(ClaimTypes.Role)?.Value;

        if (!int.TryParse(currentUserIdClaim, out var currentUserId))
        {
            return Unauthorized();
        }

        if (!string.Equals(currentRole, "Admin", StringComparison.OrdinalIgnoreCase) && currentUserId != id)
        {
            return Forbid();
        }

        var player = await db.Users.FirstOrDefaultAsync(u => u.Id == id && u.Role == UserRole.Joueur);
        if (player is null)
        {
            return NotFound();
        }

        var teamIds = await db.TeamPlayers
            .Where(tp => tp.UserId == id)
            .Select(tp => tp.TeamId)
            .ToListAsync();

        var validatedMatches = await db.Matches
            .Where(m => m.Statut == MatchStatus.Valide &&
                        (teamIds.Contains(m.Equipe1Id) || teamIds.Contains(m.Equipe2Id)))
            .ToListAsync();

        var scheduledMatches = await db.Matches
            .Where(m => m.Statut == MatchStatus.Programme &&
                        (teamIds.Contains(m.Equipe1Id) || teamIds.Contains(m.Equipe2Id)))
            .CountAsync();

        var points = await db.Participations
            .Where(p => p.JoueurId == id)
            .SumAsync(p => (int?)p.PointsObtenus) ?? 0;

        var wins = 0;
        var losses = 0;
        var draws = 0;
        var diffSets = 0;

        foreach (var match in validatedMatches)
        {
            var isTeam1 = teamIds.Contains(match.Equipe1Id);
            var myScore = isTeam1 ? (match.ScoreEquipe1 ?? 0) : (match.ScoreEquipe2 ?? 0);
            var oppScore = isTeam1 ? (match.ScoreEquipe2 ?? 0) : (match.ScoreEquipe1 ?? 0);

            diffSets += myScore - oppScore;
            if (myScore > oppScore) wins++;
            else if (myScore < oppScore) losses++;
            else draws++;
        }

        var matchsJoues = validatedMatches.Count;
        var tauxVictoire = matchsJoues == 0 ? 0 : (double)wins * 100.0 / matchsJoues;

        return Ok(new PlayerStatsResponse(
            player.Id,
            player.Nom,
            matchsJoues,
            wins,
            losses,
            draws,
            diffSets,
            points,
            scheduledMatches,
            Math.Round(tauxVictoire, 1)
        ));
    }

    [Authorize]
    [HttpGet("{id:int}/level-history")]
    public async Task<ActionResult<List<PlayerLevelHistoryResponse>>> GetLevelHistory(int id)
    {
        var currentUserIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        var currentRole = User.FindFirst(ClaimTypes.Role)?.Value;

        if (!int.TryParse(currentUserIdClaim, out var currentUserId))
        {
            return Unauthorized();
        }

        if (!string.Equals(currentRole, "Admin", StringComparison.OrdinalIgnoreCase) && currentUserId != id)
        {
            return Forbid();
        }

        var playerExists = await db.Users.AnyAsync(u => u.Id == id && u.Role == UserRole.Joueur);
        if (!playerExists)
        {
            return NotFound();
        }

        var history = await db.TechnicalTests
            .Where(t => t.JoueurId == id)
            .OrderByDescending(t => t.DateTest)
            .Select(t => new PlayerLevelHistoryResponse(
                t.Id,
                t.DateTest,
                t.ScoreTest,
                t.NiveauAttribue
            ))
            .ToListAsync();

        return Ok(history);
    }

    private static string MapCategory(int level)
    {
        if (level <= 3) return "Debutant";
        if (level <= 6) return "Intermediaire";
        if (level <= 8) return "Avance";
        return "Expert";
    }
}
