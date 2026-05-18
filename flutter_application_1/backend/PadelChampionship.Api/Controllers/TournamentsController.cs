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
public class TournamentsController(ApplicationDbContext db) : ControllerBase
{
    [Authorize(Roles = "Admin")]
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateTournamentRequest request)
    {
        if (request.PlayerIds.Count != 8)
        {
            return BadRequest("Le tournoi V1 supporte 8 joueurs (quart, demi, finale).");
        }

        var tournament = new Tournament
        {
            Nom = request.Nom,
            ClubId = request.ClubId
        };

        db.Tournaments.Add(tournament);
        await db.SaveChangesAsync();

        var quart = new List<TournamentMatch>
        {
            new() { TournamentId = tournament.Id, Round = TournamentRound.Quart, Joueur1Id = request.PlayerIds[0], Joueur2Id = request.PlayerIds[1] },
            new() { TournamentId = tournament.Id, Round = TournamentRound.Quart, Joueur1Id = request.PlayerIds[2], Joueur2Id = request.PlayerIds[3] },
            new() { TournamentId = tournament.Id, Round = TournamentRound.Quart, Joueur1Id = request.PlayerIds[4], Joueur2Id = request.PlayerIds[5] },
            new() { TournamentId = tournament.Id, Round = TournamentRound.Quart, Joueur1Id = request.PlayerIds[6], Joueur2Id = request.PlayerIds[7] }
        };

        db.TournamentMatches.AddRange(quart);
        await db.SaveChangesAsync();

        return Ok(new { tournament.Id, tournament.Nom });
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var tournaments = await db.Tournaments
            .Include(t => t.Matches)
            .OrderByDescending(t => t.Id)
            .ToListAsync();

        return Ok(tournaments.Select(t => new
        {
            t.Id,
            t.Nom,
            Matches = t.Matches.Select(m => new
            {
                m.Id,
                Round = m.Round.ToString(),
                m.Joueur1Id,
                m.Joueur2Id,
                m.VainqueurId
            })
        }));
    }

    [Authorize(Roles = "Admin")]
    [HttpPost("{id:int}/winner")]
    public async Task<IActionResult> SetWinner(int id, [FromBody] SetTournamentWinnerRequest request)
    {
        var tournament = await db.Tournaments.Include(t => t.Matches).FirstOrDefaultAsync(t => t.Id == id);
        if (tournament is null)
        {
            return NotFound();
        }

        var match = tournament.Matches.FirstOrDefault(m => m.Id == request.MatchId);
        if (match is null)
        {
            return NotFound("Match introuvable.");
        }

        if (request.WinnerId != match.Joueur1Id && request.WinnerId != match.Joueur2Id)
        {
            return BadRequest("Vainqueur invalide pour ce match.");
        }

        match.VainqueurId = request.WinnerId;
        await db.SaveChangesAsync();

        var quart = tournament.Matches.Where(m => m.Round == TournamentRound.Quart).ToList();
        var demi = tournament.Matches.Where(m => m.Round == TournamentRound.Demi).ToList();
        var finale = tournament.Matches.Where(m => m.Round == TournamentRound.Finale).ToList();

        if (quart.All(m => m.VainqueurId.HasValue) && demi.Count == 0)
        {
            db.TournamentMatches.AddRange(
                new TournamentMatch
                {
                    TournamentId = id,
                    Round = TournamentRound.Demi,
                    Joueur1Id = quart[0].VainqueurId!.Value,
                    Joueur2Id = quart[1].VainqueurId!.Value
                },
                new TournamentMatch
                {
                    TournamentId = id,
                    Round = TournamentRound.Demi,
                    Joueur1Id = quart[2].VainqueurId!.Value,
                    Joueur2Id = quart[3].VainqueurId!.Value
                }
            );
            await db.SaveChangesAsync();
        }

        if (demi.All(m => m.VainqueurId.HasValue) && demi.Count == 2 && finale.Count == 0)
        {
            db.TournamentMatches.Add(new TournamentMatch
            {
                TournamentId = id,
                Round = TournamentRound.Finale,
                Joueur1Id = demi[0].VainqueurId!.Value,
                Joueur2Id = demi[1].VainqueurId!.Value
            });
            await db.SaveChangesAsync();
        }

        return Ok();
    }
}
