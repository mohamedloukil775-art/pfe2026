using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using PadelChampionship.Api.Data;
using PadelChampionship.Api.Dtos;
using PadelChampionship.Api.Models;

namespace PadelChampionship.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public class MatchesController(ApplicationDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<List<object>>> GetAll()
    {
        var matches = await db.Matches
            .Include(m => m.Equipe1)
            .Include(m => m.Equipe2)
            .OrderByDescending(m => m.Date)
            .ToListAsync();

        return Ok(matches.Select(m => new
        {
            m.Id,
            m.Date,
            m.Terrain,
            m.Equipe1Id,
            m.Equipe2Id,
            Equipe1 = m.Equipe1.NomEquipe,
            Equipe2 = m.Equipe2.NomEquipe,
            m.ScoreEquipe1,
            m.ScoreEquipe2,
            Statut = m.Statut.ToString()
        }));
    }

    [HttpGet("mine")]
    public async Task<ActionResult<List<object>>> GetMine()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!int.TryParse(userIdClaim, out var userId))
        {
            return Unauthorized("Utilisateur introuvable.");
        }

        var myTeamIds = await db.TeamPlayers
            .Where(tp => tp.UserId == userId)
            .Select(tp => tp.TeamId)
            .ToListAsync();

        var matches = await db.Matches
            .Include(m => m.Equipe1)
            .Include(m => m.Equipe2)
            .Where(m => myTeamIds.Contains(m.Equipe1Id) || myTeamIds.Contains(m.Equipe2Id))
            .OrderByDescending(m => m.Date)
            .ToListAsync();

        return Ok(matches.Select(m => new
        {
            m.Id,
            m.Date,
            m.Terrain,
            m.Equipe1Id,
            m.Equipe2Id,
            MyEquipeId = myTeamIds.Contains(m.Equipe1Id) ? m.Equipe1Id : m.Equipe2Id,
            Equipe1 = m.Equipe1.NomEquipe,
            Equipe2 = m.Equipe2.NomEquipe,
            m.ScoreEquipe1,
            m.ScoreEquipe2,
            Statut = m.Statut.ToString()
        }));
    }

    [Authorize(Roles = "Admin")]
    [HttpPost("schedule")]
    public async Task<IActionResult> Schedule([FromBody] ScheduleMatchRequest request)
    {
        if (request.Equipe1Id == request.Equipe2Id)
        {
            return BadRequest("Les équipes doivent être différentes.");
        }

        var team1Exists = await db.Teams.AnyAsync(t => t.Id == request.Equipe1Id);
        var team2Exists = await db.Teams.AnyAsync(t => t.Id == request.Equipe2Id);
        if (!team1Exists || !team2Exists)
        {
            return NotFound("Équipe introuvable.");
        }

        db.Matches.Add(new ChampionshipMatch
        {
            Date = request.Date,
            Terrain = request.Terrain,
            Equipe1Id = request.Equipe1Id,
            Equipe2Id = request.Equipe2Id,
            Statut = MatchStatus.Programme
        });

        await db.SaveChangesAsync();
        return Ok();
    }

    [HttpPost("{id:int}/submit-score")]
    public async Task<IActionResult> SubmitScore(int id, [FromBody] SubmitScoreRequest request)
    {
        var match = await db.Matches.FirstOrDefaultAsync(m => m.Id == id);
        if (match is null)
        {
            return NotFound();
        }

        if (match.Statut == MatchStatus.Valide)
        {
            return BadRequest("Match déjà validé.");
        }

        if (DateTime.UtcNow > match.Date.AddHours(24))
        {
            match.Statut = MatchStatus.Forfait;
            await db.SaveChangesAsync();
            return BadRequest("Délai dépassé: forfait.");
        }

        if (request.EquipeId != match.Equipe1Id && request.EquipeId != match.Equipe2Id)
        {
            return BadRequest("Equipe non autorisée à saisir le score.");
        }

        match.ScoreEquipe1 = request.ScoreEquipe1;
        match.ScoreEquipe2 = request.ScoreEquipe2;
        match.Statut = MatchStatus.ResultatSaisi;

        await db.SaveChangesAsync();
        return Ok();
    }

    [Authorize(Roles = "Admin")]
    [HttpPost("{id:int}/validate")]
    public async Task<IActionResult> ValidateScore(int id, [FromBody] ValidateScoreRequest request)
    {
        var match = await db.Matches.FirstOrDefaultAsync(m => m.Id == id);
        if (match is null)
        {
            return NotFound();
        }

        match.ScoreEquipe1 = request.ScoreEquipe1;
        match.ScoreEquipe2 = request.ScoreEquipe2;
        match.Statut = MatchStatus.Valide;

        await db.SaveChangesAsync();
        await RebuildParticipationsAsync(match);

        return Ok();
    }

    [Authorize(Roles = "Admin")]
    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var match = await db.Matches.FirstOrDefaultAsync(m => m.Id == id);
        if (match is null)
        {
            return NotFound();
        }

        var participations = await db.Participations.Where(p => p.MatchId == id).ToListAsync();
        if (participations.Count > 0)
        {
            db.Participations.RemoveRange(participations);
        }

        db.Matches.Remove(match);
        await db.SaveChangesAsync();
        return NoContent();
    }

    private async Task RebuildParticipationsAsync(ChampionshipMatch match)
    {
        var old = await db.Participations.Where(p => p.MatchId == match.Id).ToListAsync();
        if (old.Count > 0)
        {
            db.Participations.RemoveRange(old);
        }

        var team1Players = await db.TeamPlayers
            .Where(tp => tp.TeamId == match.Equipe1Id)
            .Select(tp => tp.UserId)
            .ToListAsync();

        var team2Players = await db.TeamPlayers
            .Where(tp => tp.TeamId == match.Equipe2Id)
            .Select(tp => tp.UserId)
            .ToListAsync();

        var s1 = match.ScoreEquipe1 ?? 0;
        var s2 = match.ScoreEquipe2 ?? 0;

        var draw = s1 == s2;
        var team1Wins = s1 > s2;

        foreach (var joueurId in team1Players)
        {
            db.Participations.Add(new Participation
            {
                JoueurId = joueurId,
                MatchId = match.Id,
                PointsObtenus = draw ? 2 : team1Wins ? 3 : 1
            });
        }

        foreach (var joueurId in team2Players)
        {
            db.Participations.Add(new Participation
            {
                JoueurId = joueurId,
                MatchId = match.Id,
                PointsObtenus = draw ? 2 : team1Wins ? 1 : 3
            });
        }

        await db.SaveChangesAsync();
    }
}
