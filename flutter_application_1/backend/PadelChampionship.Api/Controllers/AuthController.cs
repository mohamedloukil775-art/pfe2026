using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PadelChampionship.Api.Data;
using PadelChampionship.Api.Dtos;
using PadelChampionship.Api.Models;
using PadelChampionship.Api.Services;

namespace PadelChampionship.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController(ApplicationDbContext db, IJwtTokenService jwtTokenService) : ControllerBase
{
    [HttpPost("login")]
    public async Task<ActionResult<AuthResponse>> Login([FromBody] LoginRequest request)
    {
        var user = await db.Users.FirstOrDefaultAsync(u => u.Email == request.Email);
        if (user is null)
        {
            return Unauthorized("Email ou mot de passe invalide.");
        }

        var passwordValid = BCrypt.Net.BCrypt.Verify(request.Password, user.MotDePasseHash);
        if (!passwordValid)
        {
            return Unauthorized("Email ou mot de passe invalide.");
        }

        if (user.Statut == UserStatus.Bloque)
        {
            return Unauthorized("Compte bloqué.");
        }

        var token = jwtTokenService.CreateToken(user);
        return Ok(new AuthResponse(user.Id, user.Nom, user.Email, user.Role.ToString(), token));
    }

    [HttpPost("register")]
    public async Task<ActionResult<AuthResponse>> Register([FromBody] RegisterRequest request)
    {
        // Valider les champs requis
        if (string.IsNullOrWhiteSpace(request.Nom) || 
            string.IsNullOrWhiteSpace(request.Email) || 
            string.IsNullOrWhiteSpace(request.Password))
        {
            return BadRequest("Tous les champs sont requis.");
        }

        // Valider que les passwords correspondent
        if (request.Password != request.ConfirmPassword)
        {
            return BadRequest("Les mots de passe ne correspondent pas.");
        }

        // Vérifier que l'email n'existe pas déjà
        var existingUser = await db.Users.FirstOrDefaultAsync(u => u.Email == request.Email);
        if (existingUser is not null)
        {
            return BadRequest("Cet email est déjà utilié.");
        }

        // Créer le nouvel utilisateur
        var newUser = new User
        {
            Nom = request.Nom,
            Email = request.Email,
            MotDePasseHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
            Role = UserRole.Joueur,
            Niveau = request.Niveau,
            Statut = UserStatus.Actif,
            ClubId = request.ClubId
        };

        db.Users.Add(newUser);
        await db.SaveChangesAsync();

        // Générer le token
        var token = jwtTokenService.CreateToken(newUser);

        return Ok(new AuthResponse(newUser.Id, newUser.Nom, newUser.Email, newUser.Role.ToString(), token));
    }
}
