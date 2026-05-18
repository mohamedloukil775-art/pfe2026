namespace PadelChampionship.Api.Dtos;

public record CreateTeamRequest(string NomEquipe, List<int> PlayerIds);

public record UpdateTeamRequest(string NomEquipe, List<int> PlayerIds);

public record TeamResponse(int Id, string NomEquipe, List<PlayerLite> Players);

public record PlayerLite(int Id, string Nom, int Niveau);

public record TeamMatchHistoryResponse(
	int Id,
	DateTime Date,
	string Terrain,
	int Equipe1Id,
	int Equipe2Id,
	string Equipe1,
	string Equipe2,
	int? ScoreEquipe1,
	int? ScoreEquipe2,
	string Statut
);

public record TeamStatsResponse(
	int TeamId,
	string Nom,
	int MatchsTermines,
	int MatchsProgrammes,
	int Victoires,
	int Defaites,
	int Nuls,
	int Forfaits,
	int DiffSets,
	int PointsTotal,
	double TauxVictoire,
	List<TeamMatchHistoryResponse> RecentMatches
);
