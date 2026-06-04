namespace PadelChampionship.Api.Models;

public class User
{
    public int Id { get; set; }
    public string Nom { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string MotDePasseHash { get; set; } = string.Empty;
    public UserRole Role { get; set; }
    public int Niveau { get; set; }
    public UserStatus Statut { get; set; } = UserStatus.Actif;

    public int? ClubId { get; set; }
    public Club? Club { get; set; }

    public ICollection<TeamPlayer> TeamMemberships { get; set; } = new List<TeamPlayer>();
    public ICollection<Participation> Participations { get; set; } = new List<Participation>();
}

public class Club
{
    public int Id { get; set; }
    public string Nom { get; set; } = string.Empty;
    public string Localisation { get; set; } = string.Empty;

    public ICollection<User> Joueurs { get; set; } = new List<User>();
    public ICollection<Tournament> Tournois { get; set; } = new List<Tournament>();
}

public class Team
{
    public int Id { get; set; }
    public string NomEquipe { get; set; } = string.Empty;
    public int PointsTotal { get; set; }

    public ICollection<TeamPlayer> Players { get; set; } = new List<TeamPlayer>();
}

public class TeamPlayer
{
    public int TeamId { get; set; }
    public Team Team { get; set; } = null!;

    public int UserId { get; set; }
    public User User { get; set; } = null!;
}

public class ChampionshipMatch
{
    public int Id { get; set; }
    public DateTime Date { get; set; }
    public string Terrain { get; set; } = string.Empty;

    public int Equipe1Id { get; set; }
    public Team Equipe1 { get; set; } = null!;

    public int Equipe2Id { get; set; }
    public Team Equipe2 { get; set; } = null!;

    public int? ScoreEquipe1 { get; set; }
    public int? ScoreEquipe2 { get; set; }
    public MatchStatus Statut { get; set; } = MatchStatus.Programme;
}

public class Participation
{
    public int Id { get; set; }
    public int JoueurId { get; set; }
    public User Joueur { get; set; } = null!;
    public int MatchId { get; set; }
    public ChampionshipMatch Match { get; set; } = null!;
    public int PointsObtenus { get; set; }
}

public class TechnicalTest
{
    public int Id { get; set; }
    public int JoueurId { get; set; }
    public User Joueur { get; set; } = null!;
    public DateTime DateTest { get; set; }
    public int ScoreTest { get; set; }
    public int NiveauAttribue { get; set; }
}

public class Reward
{
    public int Id { get; set; }
    public string Mois { get; set; } = string.Empty;
    public int JoueurId { get; set; }
    public User Joueur { get; set; } = null!;
    public string TypeCadeau { get; set; } = string.Empty;
}

public class Tournament
{
    public int Id { get; set; }
    public string Nom { get; set; } = string.Empty;

    public int ClubId { get; set; }
    public Club Club { get; set; } = null!;

    public ICollection<TournamentMatch> Matches { get; set; } = new List<TournamentMatch>();
}

public class TournamentMatch
{
    public int Id { get; set; }
    public TournamentRound Round { get; set; }
    public int Joueur1Id { get; set; }
    public int Joueur2Id { get; set; }
    public int? VainqueurId { get; set; }

    public int TournamentId { get; set; }
    public Tournament Tournament { get; set; } = null!;
}

public class StorageEntry
{
    public string Key { get; set; } = string.Empty;
    public string Value { get; set; } = string.Empty;
}
