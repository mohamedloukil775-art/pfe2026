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
public class StandingsController(ApplicationDbContext db) : ControllerBase
{
    [HttpGet("players")]
    public async Task<ActionResult<List<PlayerStandingResponse>>> GetPlayerStandings()
    {
        var players = await db.Users
            .Where(u => u.Role == UserRole.Joueur)
            .ToListAsync();

        var pointsByPlayer = await db.Participations
            .GroupBy(p => p.JoueurId)
            .Select(g => new { JoueurId = g.Key, Points = g.Sum(x => x.PointsObtenus), Matchs = g.Count() })
            .ToListAsync();

        var validatedMatches = await db.Matches
            .Where(m => m.Statut == MatchStatus.Valide)
            .ToListAsync();

        var teamPlayers = await db.TeamPlayers.ToListAsync();
        var playerTeamMap = teamPlayers
            .GroupBy(tp => tp.UserId)
            .ToDictionary(g => g.Key, g => g.Select(x => x.TeamId).ToHashSet());

        var standings = new List<PlayerStandingResponse>();

        foreach (var player in players)
        {
            var pointsInfo = pointsByPlayer.FirstOrDefault(p => p.JoueurId == player.Id);
            var points = pointsInfo?.Points ?? 0;
            var matchs = pointsInfo?.Matchs ?? 0;

            var myTeamIds = playerTeamMap.TryGetValue(player.Id, out var ids) ? ids : [];

            var wins = 0;
            var losses = 0;
            var diffSets = 0;

            foreach (var match in validatedMatches)
            {
                var inTeam1 = myTeamIds.Contains(match.Equipe1Id);
                var inTeam2 = myTeamIds.Contains(match.Equipe2Id);
                if (!inTeam1 && !inTeam2) continue;

                var s1 = match.ScoreEquipe1 ?? 0;
                var s2 = match.ScoreEquipe2 ?? 0;

                if (inTeam1)
                {
                    diffSets += (s1 - s2);
                    if (s1 > s2) wins++;
                    else if (s1 < s2) losses++;
                }
                else
                {
                    diffSets += (s2 - s1);
                    if (s2 > s1) wins++;
                    else if (s2 < s1) losses++;
                }
            }

            standings.Add(new PlayerStandingResponse(
                player.Id,
                player.Nom,
                points,
                matchs,
                wins,
                losses,
                diffSets,
                0));
        }

        var ordered = standings
            .OrderByDescending(s => s.Points)
            .ThenByDescending(s => s.Victoires)
            .ThenByDescending(s => s.DiffSets)
            .ToList();

        for (var i = 0; i < ordered.Count; i++)
        {
            ordered[i] = ordered[i] with { Position = i + 1 };
        }

        return Ok(ordered);
    }

    [Authorize(Roles = "Admin")]
    [HttpPost("monthly-top3")]
    public async Task<ActionResult<List<object>>> GenerateMonthlyTop3()
    {
        var standingsResult = await GetPlayerStandings();
        if (standingsResult.Result is not OkObjectResult okResult || okResult.Value is not List<PlayerStandingResponse> standings)
        {
            return BadRequest("Impossible de calculer le classement.");
        }

        var monthKey = DateTime.UtcNow.ToString("MM/yyyy");
        var top3 = standings.Take(3).ToList();

        var existing = await db.Rewards.Where(r => r.Mois == monthKey).ToListAsync();
        if (existing.Count > 0)
        {
            db.Rewards.RemoveRange(existing);
        }

        for (var i = 0; i < top3.Count; i++)
        {
            db.Rewards.Add(new Reward
            {
                Mois = monthKey,
                JoueurId = top3[i].PlayerId,
                TypeCadeau = i switch
                {
                    0 => "Trophee Or",
                    1 => "Trophee Argent",
                    _ => "Trophee Bronze"
                }
            });
        }

        await db.SaveChangesAsync();

        var output = top3.Select((t, idx) => new
        {
            Position = idx + 1,
            t.PlayerId,
            t.Nom,
            t.Points,
            Reward = idx == 0 ? "Trophee Or" : idx == 1 ? "Trophee Argent" : "Trophee Bronze"
        }).ToList<object>();

        return Ok(output);
    }
}
