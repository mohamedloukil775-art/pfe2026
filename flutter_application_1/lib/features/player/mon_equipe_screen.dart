import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/services/matches_service_mock.dart';
import '../../data/services/teams_service_mock.dart';
import '../../data/services/players_service_mock.dart';
import '../../data/services/tournaments_service_mock.dart';
import '../../domain/domain.dart';

class MonEquipeScreen extends StatefulWidget {
  final int userId;
  const MonEquipeScreen({super.key, required this.userId});

  @override
  State<MonEquipeScreen> createState() => _MonEquipeScreenState();
}

class _MonEquipeScreenState extends State<MonEquipeScreen> {
  static const _lime = Color(0xFFC8F000);
  static const _cardBg = Color(0xFF0F1621);
  static const _blue = Color(0xFF00A8FF);
  static const _red = Color(0xFFFF4757);
  static const _gold = Color(0xFFFFB800);

  final _teamsService = TeamsServiceMock();
  final _matchesService = MatchesServiceMock();
  final _tournamentsService = TournamentsServiceMock();
  final _playersService = PlayersServiceMock();

  List<Team> _myTeams = [];
  List<MatchEntry> _allMatches = [];
  List<Tournament> _allTournaments = [];
  List<Team> _allTeams = [];
  List<AppUser> _allPlayers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _teamsService.getAllTeams(),
        _matchesService.getAllMatches(),
        _tournamentsService.getAllTournaments(),
        _playersService.getAllPlayers(),
      ]);
      final teams = results[0] as List<Team>;
      final matches = results[1] as List<MatchEntry>;
      final tournaments = results[2] as List<Tournament>;
      final players = results[3] as List<AppUser>;
      if (!mounted) return;
      setState(() {
        _allTeams = teams;
        _myTeams = teams.where((t) => t.playerIds.contains(widget.userId)).toList();
        _allMatches = matches;
        _allTournaments = tournaments;
        _allPlayers = players;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<MatchEntry> _teamMatches(Team team) {
    return _allMatches
        .where((m) => m.equipe1Id == team.id || m.equipe2Id == team.id)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<Tournament> _teamTournaments(Team team) {
    return _allTournaments
        .where((t) => t.isTeamMode && t.equipeIds.contains(team.id))
        .toList();
  }

  Map<String, int> _teamStats(Team team) {
    final matches = _teamMatches(team)
        .where((m) => m.status == MatchStatus.valide && m.scoreValide != null)
        .toList();
    int wins = 0, losses = 0, draws = 0;
    for (final m in matches) {
      final s = m.scoreValide!;
      final my = m.equipe1Id == team.id ? s.setsEquipe1 : s.setsEquipe2;
      final opp = m.equipe1Id == team.id ? s.setsEquipe2 : s.setsEquipe1;
      if (my > opp) wins++;
      else if (my < opp) losses++;
      else draws++;
    }
    return {'total': _teamMatches(team).length, 'validated': matches.length, 'wins': wins, 'losses': losses, 'draws': draws};
  }

  String _teamNameById(int id) {
    try { return _allTeams.firstWhere((t) => t.id == id).nom; } catch (_) {}
    return 'Équipe #$id';
  }

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  String _formatTime(DateTime d) {
    final local = d.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _roundLabel(TournamentRound round) {
    switch (round) {
      case TournamentRound.seizieme: return '1/16';
      case TournamentRound.huitieme: return '1/8';
      case TournamentRound.quart:    return 'Quart';
      case TournamentRound.demi:     return 'Demi';
      case TournamentRound.finale:   return 'Finale';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _lime));
    }

    if (_myTeams.isEmpty) {
      return _buildNoTeam();
    }

    return RefreshIndicator(
      color: _lime,
      backgroundColor: _cardBg,
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: _myTeams.map((team) => _buildTeamSection(team)).toList(),
      ),
    );
  }

  Widget _buildTeamSection(Team team) {
    final stats = _teamStats(team);
    final teamMatches = _teamMatches(team);
    final tournaments = _teamTournaments(team);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTeamHeader(team, stats),
        const SizedBox(height: 10),
        _ExpandableSection(
          title: 'Matchs Réguliers',
          icon: Icons.sports_tennis_rounded,
          count: teamMatches.length,
          color: _blue,
          children: teamMatches.isEmpty
              ? [const _EmptyInfo('Aucun match régulier.')]
              : teamMatches.map((m) => _buildMatchCard(team, m)).toList(),
        ),
        if (tournaments.isNotEmpty) ...[
          const SizedBox(height: 10),
          _ExpandableSection(
            title: 'Tournois',
            icon: Icons.emoji_events_rounded,
            count: tournaments.length,
            color: _gold,
            children: tournaments.map((t) => _buildTournamentCard(team, t)).toList(),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  String _playerNamesForTeam(Team team) {
    final names = team.playerIds
        .map((id) {
          try { return _allPlayers.firstWhere((p) => p.id == id).nom; } catch (_) { return null; }
        })
        .whereType<String>()
        .toList();
    return names.take(2).join(' · ');
  }

  Widget _buildTeamHeader(Team team, Map<String, int> stats) {
    final playerNames = _playerNamesForTeam(team);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [_lime.withValues(alpha: 0.12), _blue.withValues(alpha: 0.06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: _lime.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          _buildTeamAvatar(team),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team.nom,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                ),
                if (playerNames.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.person_outline, size: 12, color: _lime),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        playerNames,
                        style: TextStyle(color: _lime.withValues(alpha: 0.85), fontSize: 12, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    _MiniStatChip(value: '${stats['wins']}', label: 'V', color: Colors.green),
                    const SizedBox(width: 6),
                    _MiniStatChip(value: '${stats['losses']}', label: 'D', color: _red),
                    const SizedBox(width: 6),
                    _MiniStatChip(value: '${stats['total']}', label: 'Matchs', color: _blue),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamAvatar(Team team) {
    final path = team.photoPath;
    if (path != null && path.startsWith('data:')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          base64Decode(path.split(',').last),
          width: 56, height: 56, fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: 56, height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(colors: [_lime, _blue]),
      ),
      child: Center(
        child: Text(
          team.nom.isNotEmpty ? team.nom[0].toUpperCase() : '?',
          style: const TextStyle(color: Color(0xFF080C14), fontSize: 22, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildMatchCard(Team team, MatchEntry match) {
    final score = match.scoreValide;
    final hasScore = score != null && match.status == MatchStatus.valide;
    final isEq1 = match.equipe1Id == team.id;
    final myScore = hasScore ? (isEq1 ? score.setsEquipe1 : score.setsEquipe2) : null;
    final oppScore = hasScore ? (isEq1 ? score.setsEquipe2 : score.setsEquipe1) : null;

    Color resultColor = Colors.grey;
    String resultLabel = '';
    if (myScore != null && oppScore != null) {
      if (myScore > oppScore) { resultColor = Colors.green; resultLabel = 'V'; }
      else if (myScore < oppScore) { resultColor = _red; resultLabel = 'D'; }
      else { resultColor = Colors.orange; resultLabel = 'N'; }
    }

    final opponentName = isEq1
        ? (match.equipe2Nom ?? _teamNameById(match.equipe2Id))
        : (match.equipe1Nom ?? _teamNameById(match.equipe1Id));

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: resultLabel.isNotEmpty
              ? resultColor.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'vs $opponentName',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              if (resultLabel.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: resultColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: resultColor.withValues(alpha: 0.35)),
                  ),
                  child: Text(resultLabel, style: TextStyle(color: resultColor, fontWeight: FontWeight.w800, fontSize: 12)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    match.status == MatchStatus.programme ? 'À venir' : 'En attente',
                    style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _InfoTag(icon: Icons.calendar_today_outlined, text: _formatDate(match.date)),
              _InfoTag(icon: Icons.access_time_outlined, text: _formatTime(match.date)),
              _InfoTag(icon: Icons.location_on_outlined, text: match.terrain),
            ],
          ),
          if (hasScore) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _lime.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _lime.withValues(alpha: 0.12)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sports_tennis_rounded, size: 13, color: _lime.withValues(alpha: 0.8)),
                  const SizedBox(width: 6),
                  Text(
                    'Score: ${score.setsEquipe1} - ${score.setsEquipe2}',
                    style: TextStyle(color: _lime.withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTournamentCard(Team team, Tournament tournament) {
    final myMatches = tournament.matches
        .where((m) => m.joueur1 == team.id || m.joueur2 == team.id)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _gold.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: _gold, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tournament.nom,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _InfoTag(icon: Icons.location_on_outlined, text: tournament.complexeSportif),
            ],
          ),
          const SizedBox(height: 6),
          _InfoTag(icon: Icons.calendar_today_outlined, text: _formatDate(tournament.date)),
          if (myMatches.isEmpty) ...[
            const SizedBox(height: 8),
            const Text('Pas encore de matchs', style: TextStyle(color: Colors.white38, fontSize: 12)),
          ] else ...[
            const SizedBox(height: 8),
            ...myMatches.map((m) => _buildTournamentMatchRow(team, m)),
          ],
        ],
      ),
    );
  }

  Widget _buildTournamentMatchRow(Team team, TournamentMatch m) {
    final opponentId = m.joueur1 == team.id ? m.joueur2 : m.joueur1;
    final hasResult = m.vainqueur != null && m.vainqueur! > 0;
    final iWon = hasResult && m.vainqueur == team.id;
    final resultColor = iWon ? Colors.green : (hasResult ? _red : Colors.grey);
    final resultLabel = iWon ? 'V' : (hasResult ? 'D' : '');

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: iWon
            ? Colors.green.withValues(alpha: 0.06)
            : (hasResult ? _red.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.03)),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasResult ? resultColor.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(_roundLabel(m.round),
                    style: const TextStyle(color: _gold, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  opponentId == 0 ? 'Adversaire à déterminer' : 'vs ${_teamNameById(opponentId)}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (resultLabel.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: resultColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(resultLabel, style: TextStyle(color: resultColor, fontWeight: FontWeight.w800, fontSize: 12)),
                )
              else
                Text(opponentId == 0 ? '...' : 'À jouer',
                    style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _InfoTag(icon: Icons.location_on_outlined, text: '${m.complexeSportif} · T${m.terrainNumero}'),
              _InfoTag(icon: Icons.access_time_outlined, text: m.heureDebut),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoTeam() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _lime.withValues(alpha: 0.08),
                border: Border.all(color: _lime.withValues(alpha: 0.15)),
              ),
              child: Icon(Icons.group_off_rounded, size: 52, color: _lime.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 20),
            const Text('Aucune équipe',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Vous n\'êtes dans aucune équipe.\nContactez l\'administrateur.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _ExpandableSection extends StatefulWidget {
  const _ExpandableSection({
    required this.title,
    required this.icon,
    required this.count,
    required this.color,
    required this.children,
  });

  final String title;
  final IconData icon;
  final int count;
  final Color color;
  final List<Widget> children;

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  bool _expanded = true;

  static const _cardBg = Color(0xFF0F1621);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 15),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(widget.title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${widget.count}',
                        style: TextStyle(color: widget.color, fontWeight: FontWeight.w700, fontSize: 11)),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white38,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded && widget.children.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: widget.children),
            ),
        ],
      ),
    );
  }
}

class _MiniStatChip extends StatelessWidget {
  const _MiniStatChip({required this.value, required this.label, required this.color});
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 11)),
        ],
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: Colors.white38),
        const SizedBox(width: 4),
        Flexible(
          child: Text(text,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _EmptyInfo extends StatelessWidget {
  const _EmptyInfo(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(message, style: const TextStyle(color: Colors.white38, fontSize: 12)),
    );
  }
}
