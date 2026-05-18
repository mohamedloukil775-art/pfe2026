namespace PadelChampionship.Api.Dtos;

public record LoginRequest(string Email, string Password);

public record RegisterRequest(
    string Nom,
    string Email,
    string Password,
    string ConfirmPassword,
    int Niveau = 3,
    int? ClubId = null
);

public record AuthResponse(
    int Id,
    string Nom,
    string Email,
    string Role,
    string Token
);
