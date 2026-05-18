namespace PadelChampionship.Api.Models;

public enum UserRole
{
    Admin = 1,
    Joueur = 2
}

public enum UserStatus
{
    Actif = 1,
    Bloque = 2
}

public enum MatchStatus
{
    Programme = 1,
    ResultatSaisi = 2,
    Valide = 3,
    Forfait = 4
}

public enum TournamentRound
{
    Quart = 1,
    Demi = 2,
    Finale = 3
}
