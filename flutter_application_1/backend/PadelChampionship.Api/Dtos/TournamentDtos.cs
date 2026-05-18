namespace PadelChampionship.Api.Dtos;

public record CreateTournamentRequest(string Nom, int ClubId, List<int> PlayerIds);

public record SetTournamentWinnerRequest(int MatchId, int WinnerId);
