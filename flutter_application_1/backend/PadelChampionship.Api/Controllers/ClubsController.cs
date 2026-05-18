using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PadelChampionship.Api.Data;
using PadelChampionship.Api.Models;

namespace PadelChampionship.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public class ClubsController(ApplicationDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var clubs = await db.Clubs
            .Include(c => c.Joueurs)
            .Include(c => c.Tournois)
            .Select(c => new
            {
                c.Id,
                c.Nom,
                c.Localisation,
                NombreJoueurs = c.Joueurs.Count,
                NombreTournois = c.Tournois.Count
            })
            .ToListAsync();

        return Ok(clubs);
    }

    [HttpGet("rankings")]
    public async Task<IActionResult> GetClubRankings()
    {
        var clubs = await db.Clubs
            .Include(c => c.Joueurs)
            .ToListAsync();

        var pointsByPlayer = await db.Participations
            .GroupBy(p => p.JoueurId)
            .Select(g => new { JoueurId = g.Key, Points = g.Sum(x => x.PointsObtenus) })
            .ToDictionaryAsync(x => x.JoueurId, x => x.Points);

        var rankings = clubs
            .Select(c =>
            {
                var joueurs = c.Joueurs.Where(j => j.Role == UserRole.Joueur).ToList();
                var totalPoints = joueurs.Sum(j => pointsByPlayer.TryGetValue(j.Id, out var pts) ? pts : 0);
                var averageLevel = joueurs.Count == 0 ? 0 : joueurs.Average(j => j.Niveau);

                return new
                {
                    c.Id,
                    c.Nom,
                    c.Localisation,
                    NombreJoueurs = joueurs.Count,
                    PointsTotal = totalPoints,
                    NiveauMoyen = Math.Round(averageLevel, 2)
                };
            })
            .OrderByDescending(x => x.PointsTotal)
            .ThenByDescending(x => x.NiveauMoyen)
            .ThenByDescending(x => x.NombreJoueurs)
            .ToList();

        var output = rankings
            .Select((club, index) => new
            {
                Position = index + 1,
                club.Id,
                club.Nom,
                club.Localisation,
                club.NombreJoueurs,
                club.PointsTotal,
                club.NiveauMoyen
            })
            .ToList();

        return Ok(output);
    }

    [Authorize(Roles = "Admin")]
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] Club request)
    {
        if (string.IsNullOrWhiteSpace(request.Nom))
        {
            return BadRequest("Nom du club obligatoire.");
        }

        var club = new Club
        {
            Nom = request.Nom,
            Localisation = request.Localisation
        };

        db.Clubs.Add(club);
        await db.SaveChangesAsync();

        return Ok(new { club.Id, club.Nom, club.Localisation });
    }
}
