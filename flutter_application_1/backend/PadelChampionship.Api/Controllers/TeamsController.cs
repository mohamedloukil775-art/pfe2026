using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PadelChampionship.Api.Data;
using PadelChampionship.Api.Dtos;
using PadelChampionship.Api.Models;

namespace PadelChampionship.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public class TeamsController(ApplicationDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<List<TeamResponse>>> GetAll()
    {
        var teams = await db.Teams
            .Include(t => t.Players)
            .ThenInclude(tp => tp.User)
            .ToListAsync();

        var result = teams.Select(t => new TeamResponse(
            t.Id,
            t.NomEquipe,
            t.Players
                .Select(p => new PlayerLite(p.UserId, p.User.Nom, p.User.Niveau))
                .ToList()
        )).ToList();

        return Ok(result);
    }

    [HttpGet("{id:int}/stats")]
    public async Task<ActionResult<TeamStatsResponse>> GetStats(int id)
    {
        var team = await db.Teams.FirstOrDefaultAsync(t => t.Id == id);
        if (team is null)
        {
            return NotFound();
        }

        var relatedMatches = await db.Matches
            .Include(m => m.Equipe1)
            .Include(m => m.Equipe2)
            .Where(m => m.Equipe1Id == id || m.Equipe2Id == id)
            .OrderByDescending(m => m.Date)
            .ToListAsync();

        var completedMatches = relatedMatches
            .Where(m => m.Statut == MatchStatus.Valide || m.Statut == MatchStatus.Forfait)
            .ToList();

        var validatedMatches = relatedMatches
            .Where(m => m.Statut == MatchStatus.Valide)
            .ToList();

        var wins = 0;
        var losses = 0;
        var draws = 0;
        var forfeits = relatedMatches.Count(m => m.Statut == MatchStatus.Forfait);
        var diffSets = 0;

        foreach (var match in validatedMatches)
        {
            var isTeam1 = match.Equipe1Id == id;
            var myScore = isTeam1 ? (match.ScoreEquipe1 ?? 0) : (match.ScoreEquipe2 ?? 0);
            var oppScore = isTeam1 ? (match.ScoreEquipe2 ?? 0) : (match.ScoreEquipe1 ?? 0);

            diffSets += myScore - oppScore;
            if (myScore > oppScore) wins++;
            else if (myScore < oppScore) losses++;
            else draws++;
        }

        var pointsTotal = wins * 3 + draws;
        var tauxVictoire = completedMatches.Count == 0 ? 0 : (double)wins * 100.0 / completedMatches.Count;
        var programmedMatches = relatedMatches.Count(m => m.Statut == MatchStatus.Programme);

        var recentMatches = relatedMatches.Take(5).Select(m => new TeamMatchHistoryResponse(
            m.Id,
            m.Date,
            m.Terrain,
            m.Equipe1Id,
            m.Equipe2Id,
            m.Equipe1.NomEquipe,
            m.Equipe2.NomEquipe,
            m.ScoreEquipe1,
            m.ScoreEquipe2,
            m.Statut.ToString()
        )).ToList();

        return Ok(new TeamStatsResponse(
            team.Id,
            team.NomEquipe,
            completedMatches.Count,
            programmedMatches,
            wins,
            losses,
            draws,
            forfeits,
            diffSets,
            pointsTotal,
            Math.Round(tauxVictoire, 1),
            recentMatches
        ));
    }

    [Authorize(Roles = "Admin")]
    [HttpPost]
    public async Task<ActionResult<TeamResponse>> Create([FromBody] CreateTeamRequest request)
    {
        if (request.PlayerIds.Count != 2)
        {
            return BadRequest("Une équipe doit contenir exactement 2 joueurs.");
        }

        var players = await db.Users
            .Where(u => request.PlayerIds.Contains(u.Id) && u.Role == UserRole.Joueur)
            .ToListAsync();

        if (players.Count != 2)
        {
            return BadRequest("Joueurs invalides.");
        }

        var team = new Team { NomEquipe = request.NomEquipe };
        db.Teams.Add(team);
        await db.SaveChangesAsync();

        var links = players.Select(p => new TeamPlayer
        {
            TeamId = team.Id,
            UserId = p.Id
        });

        db.TeamPlayers.AddRange(links);
        await db.SaveChangesAsync();

        return Ok(new TeamResponse(
            team.Id,
            team.NomEquipe,
            players.Select(p => new PlayerLite(p.Id, p.Nom, p.Niveau)).ToList()
        ));
    }

    [Authorize(Roles = "Admin")]
    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var team = await db.Teams
            .Include(t => t.Players)
            .FirstOrDefaultAsync(t => t.Id == id);
        if (team is null)
        {
            return NotFound();
        }

        var hasLinkedMatches = await db.Matches
            .AnyAsync(m => m.Equipe1Id == id || m.Equipe2Id == id);
        if (hasLinkedMatches)
        {
            return BadRequest("Impossible de supprimer cette equipe: elle est liee a des matchs existants.");
        }

        db.TeamPlayers.RemoveRange(team.Players);
        db.Teams.Remove(team);
        await db.SaveChangesAsync();
        return NoContent();
    }

    [Authorize(Roles = "Admin")]
    [HttpPut("{id:int}")]
    public async Task<ActionResult<TeamResponse>> Update(int id, [FromBody] UpdateTeamRequest request)
    {
        var team = await db.Teams
            .Include(t => t.Players)
            .FirstOrDefaultAsync(t => t.Id == id);
        if (team is null)
        {
            return NotFound();
        }

        if (request.PlayerIds.Count != 2)
        {
            return BadRequest("Une équipe doit contenir exactement 2 joueurs.");
        }

        var players = await db.Users
            .Where(u => request.PlayerIds.Contains(u.Id) && u.Role == UserRole.Joueur)
            .ToListAsync();

        if (players.Count != 2)
        {
            return BadRequest("Joueurs invalides.");
        }

        team.NomEquipe = request.NomEquipe;
        db.TeamPlayers.RemoveRange(team.Players);
        db.TeamPlayers.AddRange(players.Select(p => new TeamPlayer
        {
            TeamId = team.Id,
            UserId = p.Id
        }));

        await db.SaveChangesAsync();

        return Ok(new TeamResponse(
            team.Id,
            team.NomEquipe,
            players.Select(p => new PlayerLite(p.Id, p.Nom, p.Niveau)).ToList()
        ));
    }
}
