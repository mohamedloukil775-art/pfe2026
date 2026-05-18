namespace PadelChampionship.Api.Dtos;

public record ScheduleMatchRequest(
    DateTime Date,
    string Terrain,
    int Equipe1Id,
    int Equipe2Id
);

public record SubmitScoreRequest(
    int EquipeId,
    int ScoreEquipe1,
    int ScoreEquipe2
);

public record ValidateScoreRequest(int ScoreEquipe1, int ScoreEquipe2);

public record TeamStandingResponse(
    int Id,
    string Nom,
    int Points
);

public record PlayerStandingResponse(
    int PlayerId,
    string Nom,
    int Points,
    int MatchsJoues,
    int Victoires,
    int Defaites,
    int DiffSets,
    int Position
);
