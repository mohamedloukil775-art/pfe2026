namespace PadelChampionship.Api.Dtos;

public record CreatePlayerRequest(
    string Nom,
    string Email,
    string Password,
    int Niveau,
    int? ClubId
);

public record PlayerResponse(
    int Id,
    string Nom,
    string Email,
    int Niveau,
    string Categorie,
    string Statut,
    int? ClubId
);

public record UpdatePlayerLevelRequest(int Niveau, int ScoreTest);

public record PlayerStatsResponse(
    int PlayerId,
    string Nom,
    int MatchsJoues,
    int Victoires,
    int Defaites,
    int Nuls,
    int DiffSets,
    int Points,
    int MatchsProgrammes,
    double TauxVictoire
);

public record PlayerLevelHistoryResponse(
    int Id,
    DateTime DateTest,
    int ScoreTest,
    int NiveauAttribue
);
