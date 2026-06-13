import 'package:flutter/material.dart';

import '../../data/services/services.dart';
import '../../domain/domain.dart';

enum MatchViewFilter { all, upcoming, history, matchs, tournois }

class MesMatchsScreen extends StatefulWidget {
  const MesMatchsScreen({super.key, required this.userId, this.teamIds = const []});

  final int userId;
  final List<int> teamIds;

  @override
  State<MesMatchsScreen> createState() => _MesMatchsScreenState();
}

class _MesMatchsScreenState extends State<MesMatchsScreen> {
  static const _lime = Color(0xFFC8F000);
  static const _cardBg = Color(0xFF0F1621);

  final MatchesServiceMock _matchesService = MatchesServiceMock();
  final StandingsServiceMock _standingsService = StandingsServiceMock();
  final PlayersServiceMock _playersService = PlayersServiceMock();
  final TournamentsServiceMock _tournamentService = TournamentsServiceMock();
  final TeamsServiceMock _teamsService = TeamsServiceMock();

  List<MatchEntry> _myMatches = const [];
  List<PlayerStanding> _standings = const [];
  List<NiveauHistory> _levelHistory = const [];
  PlayerStats? _stats;
  List<Tournament> _myTournaments = const [];
  List<AppUser> _allPlayers = const [];
  List<Team> _allTeams = const [];
  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _error;
  MatchViewFilter _viewFilter = MatchViewFilter.all;
  String _historySearch = '';
  String _historyResultFilter = 'Tous';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant MesMatchsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.teamIds.length != widget.teamIds.length ||
        !oldWidget.teamIds.every((id) => widget.teamIds.contains(id))) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _matchesService.getMyMatches(teamIds: widget.teamIds),
        _standingsService.getStandings(),
        _playersService.getPlayerStats(widget.userId, teamIds: widget.teamIds),
        _playersService.getLevelHistory(widget.userId),
        _tournamentService.getTournamentsForPlayer(widget.userId, teamIds: widget.teamIds),
        _playersService.getAllPlayers(),
        _teamsService.getAllTeams(),
      ]);

      if (!mounted) return;
      setState(() {
        _myMatches = List<MatchEntry>.from(results[0] as List<MatchEntry>)
          ..sort((a, b) => b.date.compareTo(a.date));
        _standings = results[1] as List<PlayerStanding>;
        _stats = results[2] as PlayerStats;
        _levelHistory = results[3] as List<NiveauHistory>;
        _myTournaments = List<Tournament>.from(results[4] as List<Tournament>);
        _allPlayers = List<AppUser>.from(results[5] as List<AppUser>);
        _allTeams = List<Team>.from(results[6] as List<Team>);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('ApiException: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _runAction(
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    setState(() => _isActionLoading = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('ApiException: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  List<MatchEntry> get _upcomingMatches =>
      _myMatches.where((m) => m.status == MatchStatus.programme).toList();

  List<MatchEntry> get _historyMatches =>
      _myMatches.where((m) => m.status != MatchStatus.programme).toList();

  List<MatchEntry> get _filteredHistoryMatches {
    var list = _historyMatches;

    // Filtre par résultat
    if (_historyResultFilter == 'Victoires') {
      list = list.where((m) {
        final s = m.scoreValide;
        if (s == null || m.myEquipeId == null) return false;
        final isEq1 = m.myEquipeId == m.equipe1Id;
        final my = isEq1 ? s.setsEquipe1 : s.setsEquipe2;
        final opp = isEq1 ? s.setsEquipe2 : s.setsEquipe1;
        return my > opp;
      }).toList();
    } else if (_historyResultFilter == 'Défaites') {
      list = list.where((m) {
        final s = m.scoreValide;
        if (s == null || m.myEquipeId == null) return false;
        final isEq1 = m.myEquipeId == m.equipe1Id;
        final my = isEq1 ? s.setsEquipe1 : s.setsEquipe2;
        final opp = isEq1 ? s.setsEquipe2 : s.setsEquipe1;
        return my < opp;
      }).toList();
    }

    // Filtre par recherche (nom équipe ou terrain)
    if (_historySearch.trim().isNotEmpty) {
      final q = _historySearch.trim().toLowerCase();
      list = list.where((m) {
        final eq1 = _teamName(m, true).toLowerCase();
        final eq2 = _teamName(m, false).toLowerCase();
        final terrain = m.terrain.toLowerCase();
        return eq1.contains(q) || eq2.contains(q) || terrain.contains(q);
      }).toList();
    }

    return list;
  }

  String _statusLabel(MatchStatus status) {
    switch (status) {
      case MatchStatus.programme:
        return 'Programme';
      case MatchStatus.resultatSaisi:
        return 'Résultat en attente';
      case MatchStatus.valide:
        return 'Valide';
      case MatchStatus.forfait:
        return 'Forfait';
    }
  }

  Color _statusColor(MatchStatus status) {
    switch (status) {
      case MatchStatus.programme:
        return Colors.blue;
      case MatchStatus.resultatSaisi:
        return Colors.orange;
      case MatchStatus.valide:
        return Colors.green;
      case MatchStatus.forfait:
        return Colors.red;
    }
  }

  String _teamNameById(int id) {
    return 'Equipe #$id';
  }

  String _teamName(MatchEntry match, bool isFirst) {
    if (isFirst) {
      return match.equipe1Nom ?? _teamNameById(match.equipe1Id);
    }
    return match.equipe2Nom ?? _teamNameById(match.equipe2Id);
  }

  int? get _myPosition {
    for (var i = 0; i < _standings.length; i++) {
      if (_standings[i].joueurId == widget.userId) return i + 1;
    }
    return null;
  }

  int get _myPoints {
    for (final standing in _standings) {
      if (standing.joueurId == widget.userId) return standing.points;
    }
    return 0;
  }

  String _formCode(MatchEntry match) {
    if (match.status == MatchStatus.valide && match.myEquipeId != null && match.scoreValide != null) {
      final myScore = match.myEquipeId == match.equipe1Id
          ? match.scoreValide!.setsEquipe1
          : match.scoreValide!.setsEquipe2;
      final oppScore = match.myEquipeId == match.equipe1Id
          ? match.scoreValide!.setsEquipe2
          : match.scoreValide!.setsEquipe1;

      if (myScore > oppScore) return 'V';
      if (myScore < oppScore) return 'D';
      return 'N';
    }

    if (match.status == MatchStatus.forfait) return 'F';
    if (match.status == MatchStatus.resultatSaisi) return 'S';
    return '-';
  }

  Color _formColor(String code) {
    switch (code) {
      case 'V':
        return Colors.green;
      case 'D':
      case 'F':
        return Colors.red;
      case 'N':
        return Colors.orange;
      case 'S':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$d/$m/$y';
  }

  // ── Tournament helpers ──────────────────────────────────────────────────────


  String _participantName(Tournament t, int id) {
    if (id == 0) return '?';
    if (t.isTeamMode) {
      try { return _allTeams.firstWhere((tm) => tm.id == id).nom; } catch (_) {}
      return 'Équipe #$id';
    }
    try { return _allPlayers.firstWhere((p) => p.id == id).nom; } catch (_) {}
    return 'Joueur #$id';
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

  Widget _buildTournamentSection() {
    if (_myTournaments.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        _SectionTitle(label: 'Mes Tournois'),
        const SizedBox(height: 10),
        ..._myTournaments.map(_buildTournamentCard),
      ],
    );
  }

  Widget _buildTournamentCard(Tournament t) {
    const gold = Color(0xFFFFB800);
    // Group matches by round for display
    final rounds = <TournamentRound, List<TournamentMatch>>{};
    for (final m in t.matches) {
      rounds.putIfAbsent(m.round, () => []).add(m);
    }
    final roundOrder = [
      TournamentRound.seizieme,
      TournamentRound.huitieme,
      TournamentRound.quart,
      TournamentRound.demi,
      TournamentRound.finale,
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: gold.withValues(alpha: 0.18)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(children: [
            const Icon(Icons.emoji_events_rounded, color: gold, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(t.nom,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: t.isTeamMode
                    ? Colors.blue.withValues(alpha: 0.15)
                    : Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                t.isTeamMode ? 'Équipes' : 'Joueurs',
                style: TextStyle(
                  color: t.isTeamMode ? Colors.blue : Colors.green,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          if (t.matches.isEmpty)
            Text('Tableau non encore généré',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13))
          else
            ...roundOrder
                .where((r) => rounds.containsKey(r))
                .expand((r) => [
                  // Round title
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 4),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: gold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(_roundLabel(r),
                            style: const TextStyle(
                                color: gold, fontSize: 10, fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.08))),
                    ]),
                  ),
                  ...rounds[r]!.map((m) => _buildTournamentMatchRow(t, m)),
                ]),
        ],
      ),
    );
  }

  Widget _buildTournamentMatchRow(Tournament t, TournamentMatch m) {
    // Determine if this player/team is in this match
    final isMyMatch = t.isTeamMode
        ? widget.teamIds.any((tid) => m.joueur1 == tid || m.joueur2 == tid)
        : (m.joueur1 == widget.userId || m.joueur2 == widget.userId);

    final myId = t.isTeamMode
        ? (widget.teamIds.firstWhere(
            (tid) => m.joueur1 == tid || m.joueur2 == tid,
            orElse: () => -1,
          ))
        : widget.userId;
    final hasResult = m.vainqueur != null && m.vainqueur! > 0;
    final iWon = isMyMatch && hasResult && m.vainqueur == myId;
    final iLost = isMyMatch && hasResult && m.vainqueur != myId;

    final p1Name = _participantName(t, m.joueur1);
    final p2Name = _participantName(t, m.joueur2);
    final winnerName = hasResult ? _participantName(t, m.vainqueur!) : null;

    Color borderColor = Colors.white.withValues(alpha: 0.08);
    Color bgColor = Colors.white.withValues(alpha: 0.03);
    if (isMyMatch) {
      if (iWon)        { bgColor = Colors.green.withValues(alpha: 0.07); borderColor = Colors.green.withValues(alpha: 0.30); }
      else if (iLost)  { bgColor = Colors.red.withValues(alpha: 0.07);   borderColor = Colors.red.withValues(alpha: 0.30); }
      else             { bgColor = _lime.withValues(alpha: 0.05);         borderColor = _lime.withValues(alpha: 0.25); }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Ligne 1 : heure · terrain · complexe ──────────────────────
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _TournamentInfoChip(
                icon: Icons.access_time_rounded,
                label: m.heureDebut,
                color: const Color(0xFF5AA9FF),
              ),
              _TournamentInfoChip(
                icon: Icons.stadium_outlined,
                label: 'Terrain ${m.terrainNumero}',
                color: const Color(0xFF58D6B0),
              ),
              _TournamentInfoChip(
                icon: Icons.location_on_outlined,
                label: m.complexeSportif,
                color: const Color(0xFFF59E0B),
              ),
              if (isMyMatch)
                _TournamentInfoChip(
                  icon: Icons.person_pin_outlined,
                  label: 'Mon match',
                  color: _lime,
                ),
            ],
          ),
          const SizedBox(height: 8),
          // ── Ligne 2 : participants avec scores ────────────────────────
          _buildScoreTable(m, p1Name, p2Name),
          // ── Ligne 3 : résultat ────────────────────────────────────────
          if (hasResult) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.emoji_events_outlined, color: Color(0xFFFFB800), size: 13),
              const SizedBox(width: 4),
              Text('Qualifié : $winnerName',
                  style: const TextStyle(
                      color: Color(0xFFFFB800), fontSize: 11.5, fontWeight: FontWeight.w700)),
              if (isMyMatch) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: iWon
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    iWon ? 'Victoire' : 'Défaite',
                    style: TextStyle(
                        color: iWon ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w800,
                        fontSize: 11),
                  ),
                ),
              ],
            ]),
          ] else if (m.joueur1 > 0 && m.joueur2 > 0)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text('Résultat en attente',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35), fontSize: 11)),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text('En attente du tour précédent',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.25), fontSize: 11)),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _lime.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _lime, size: 16),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScoreTable(TournamentMatch m, String p1Name, String p2Name) {
    // Parse set scores: "6-4" → j1=6, j2=4
    List<(int, int)> sets = [];
    for (final s in [m.scoreSet1, m.scoreSet2, m.scoreSet3]) {
      if (s == null) continue;
      final parts = s.split('-');
      final a = int.tryParse(parts.firstOrNull ?? '');
      final b = int.tryParse(parts.lastOrNull ?? '');
      if (a != null && b != null) sets.add((a, b));
    }

    final p1IsWinner = m.vainqueur == m.joueur1;
    final p2IsWinner = m.vainqueur == m.joueur2;
    const winColor = Color(0xFF22C55E);

    Widget nameText(String name, bool isWinner) => Expanded(
      child: Text(
        name,
        style: TextStyle(
          color: isWinner ? winColor : Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );

    Widget setScore(int score, bool isWinner) => Container(
      width: 26,
      height: 26,
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: isWinner
            ? winColor.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: isWinner
              ? winColor.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Center(
        child: Text(
          '$score',
          style: TextStyle(
            color: isWinner ? winColor : Colors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Player 1 row
        Row(children: [
          if (p1IsWinner) const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Icon(Icons.emoji_events_outlined, color: Color(0xFFFFB800), size: 13),
          ),
          nameText(m.joueur1 > 0 ? p1Name : '?', p1IsWinner),
          if (sets.isNotEmpty)
            ...sets.asMap().entries.map((e) {
              final p1s = e.value.$1;
              final p2s = e.value.$2;
              return setScore(p1s, p1s > p2s);
            }),
        ]),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
        ),
        // Player 2 row
        Row(children: [
          if (p2IsWinner) const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Icon(Icons.emoji_events_outlined, color: Color(0xFFFFB800), size: 13),
          ),
          nameText(m.joueur2 > 0 ? p2Name : '?', p2IsWinner),
          if (sets.isNotEmpty)
            ...sets.asMap().entries.map((e) {
              final p1s = e.value.$1;
              final p2s = e.value.$2;
              return setScore(p2s, p2s > p1s);
            }),
        ]),
        if (sets.isEmpty && m.joueur1 > 0 && m.joueur2 > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              m.vainqueur != null ? 'Résultat enregistré' : 'Score non encore saisi',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35), fontSize: 10.5),
            ),
          ),
      ],
    );
  }

  Widget _buildRecentFormCard() {
    final lastFive = _historyMatches.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _lime.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.timeline_rounded, 'Forme récente', '5 derniers matchs'),
          const SizedBox(height: 14),
          if (lastFive.isEmpty)
            Text(
              'Pas encore de matchs terminés.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
            )
          else
            Wrap(
              spacing: 8,
              children: lastFive.map(_formCode).map((code) {
                return Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_formColor(code), _formColor(code).withValues(alpha: 0.7)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _formColor(code).withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      code,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildLevelEvolutionCard() {
    if (_levelHistory.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _lime.withValues(alpha: 0.1)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.bar_chart_rounded, 'Évolution du niveau', 'Tests techniques'),
            const SizedBox(height: 12),
            Text(
              'Aucun test technique enregistré pour le moment.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
            ),
          ],
        ),
      );
    }

    final chronological = _levelHistory.take(6).toList().reversed.toList();
    final maxLevel = chronological.fold<int>(
      1,
      (highest, entry) => entry.niveauAttribue > highest ? entry.niveauAttribue : highest,
    );
    final currentLevel = chronological.last.niveauAttribue;
    final firstLevel = chronological.first.niveauAttribue;
    final trendDelta = currentLevel - firstLevel;
    final trendLabel = trendDelta > 0 ? '+$trendDelta' : trendDelta < 0 ? '$trendDelta' : 'stable';
    final trendColor = trendDelta > 0 ? Colors.green : trendDelta < 0 ? Colors.red : Colors.orange;

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _lime.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSectionHeader(Icons.bar_chart_rounded, 'Évolution du niveau', 'Tests techniques'),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: trendColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  trendLabel,
                  style: TextStyle(
                    color: trendColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: chronological.map((entry) {
                  final barHeight = 40 + ((entry.niveauAttribue / maxLevel) * 140);
                  final isLatest = entry == chronological.last;
                  final barColor = isLatest ? _lime : _lime.withValues(alpha: 0.35);
                  return Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          entry.niveauAttribue.toString(),
                          style: TextStyle(
                            color: isLatest ? _lime : Colors.white54,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 40,
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: isLatest
                                ? [
                                    BoxShadow(
                                      color: _lime.withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 64,
                          child: Text(
                            _formatDate(entry.dateTest),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 64,
                          child: Text(
                            'Score ${entry.scoreTest}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSubmitScoreDialog(MatchEntry match) async {
    if (match.myEquipeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de déterminer votre équipe.'), backgroundColor: Colors.red),
      );
      return;
    }

    final eq1Name = _teamName(match, true);
    final eq2Name = _teamName(match, false);
    final selectedEquipeId = match.myEquipeId!;

    int s1e1 = 0, s1e2 = 0;
    int s2e1 = 0, s2e2 = 0;
    final s3e1Ctrl = TextEditingController();
    final s3e2Ctrl = TextEditingController();

    bool needsSet3(int v1e1, int v1e2, int v2e1, int v2e2) {
      int w1 = 0, w2 = 0;
      if (v1e1 > v1e2) w1++; else if (v1e2 > v1e1) w2++;
      if (v2e1 > v2e2) w1++; else if (v2e2 > v2e1) w2++;
      return w1 == 1 && w2 == 1;
    }

    // Returns equipe index (1 or 2) or null if not decided
    int? autoWinner(int v1e1, int v1e2, int v2e1, int v2e2) {
      int w1 = 0, w2 = 0;
      if (v1e1 > v1e2) w1++; else if (v1e2 > v1e1) w2++;
      if (v2e1 > v2e2) w1++; else if (v2e2 > v2e1) w2++;
      if (w1 == 2) return 1;
      if (w2 == 2) return 2;
      final v3e1 = int.tryParse(s3e1Ctrl.text) ?? -1;
      final v3e2 = int.tryParse(s3e2Ctrl.text) ?? -1;
      if (v3e1 < 0 || v3e2 < 0) return null;
      final maxS = v3e1 > v3e2 ? v3e1 : v3e2;
      final diff = (v3e1 - v3e2).abs();
      if (maxS < 10 || diff < 2) return null;
      return v3e1 > v3e2 ? 1 : 2;
    }

    final result = await showDialog<({int sets1, int sets2, String s1, String s2, String? s3})>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        final needs3 = needsSet3(s1e1, s1e2, s2e1, s2e2);
        final winner = autoWinner(s1e1, s1e2, s2e1, s2e2);

        Widget numBtn(int n, int current, ValueChanged<int> onTap) {
          final sel = n == current;
          return GestureDetector(
            onTap: () => onTap(n),
            child: Container(
              width: 30, height: 30,
              margin: const EdgeInsets.only(right: 4, bottom: 4),
              decoration: BoxDecoration(
                color: sel ? _lime : Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: sel ? _lime : Colors.white.withValues(alpha: 0.15)),
              ),
              child: Center(child: Text('$n',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                    color: sel ? const Color(0xFF080C14) : Colors.white70))),
            ),
          );
        }

        Widget pickerRow(String label, int valE1, int valE2,
            ValueChanged<int> onE1, ValueChanged<int> onE2) {
          final nums = List.generate(8, (i) => i);
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white70)),
            const SizedBox(height: 6),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 72,
                child: Text(eq1Name, style: const TextStyle(fontSize: 10, color: Colors.white54),
                  overflow: TextOverflow.ellipsis)),
              Expanded(child: Wrap(children: nums.map((n) => numBtn(n, valE1, onE1)).toList())),
            ]),
            const SizedBox(height: 4),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 72,
                child: Text(eq2Name, style: const TextStyle(fontSize: 10, color: Colors.white54),
                  overflow: TextOverflow.ellipsis)),
              Expanded(child: Wrap(children: nums.map((n) => numBtn(n, valE2, onE2)).toList())),
            ]),
          ]);
        }

        Widget scoreField(String hint, TextEditingController ctrl) => Expanded(
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
            decoration: InputDecoration(
              hintText: hint, hintStyle: const TextStyle(fontSize: 11),
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              isDense: true,
            ),
            onChanged: (_) => setS(() {}),
          ),
        );

        return AlertDialog(
          backgroundColor: const Color(0xFF0F1621),
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Saisir le score', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('$eq1Name  vs  $eq2Name',
              style: const TextStyle(fontSize: 12, color: _lime, fontWeight: FontWeight.w600)),
          ]),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
              pickerRow('Manche 1', s1e1, s1e2,
                (v) => setS(() => s1e1 = v), (v) => setS(() => s1e2 = v)),
              const SizedBox(height: 14),
              pickerRow('Manche 2', s2e1, s2e2,
                (v) => setS(() => s2e1 = v), (v) => setS(() => s2e2 = v)),
              if (needs3) ...[
                const SizedBox(height: 14),
                Text('Manche 3', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white70)),
                const SizedBox(height: 6),
                Row(children: [
                  scoreField(eq1Name.split(' ').first, s3e1Ctrl),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('-', style: TextStyle(color: Colors.white54, fontSize: 18, fontWeight: FontWeight.w800))),
                  scoreField(eq2Name.split(' ').first, s3e2Ctrl),
                ]),
                Padding(padding: const EdgeInsets.only(top: 4),
                  child: Text('Super tie-break · premier à 10 · différence ≥ 2',
                    style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.35)),
                    textAlign: TextAlign.center)),
              ],
              if (winner != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB800).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFB800).withValues(alpha: 0.35)),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.emoji_events, color: Color(0xFFFFB800), size: 16),
                    const SizedBox(width: 6),
                    Text('Vainqueur : ${winner == 1 ? eq1Name : eq2Name}',
                      style: const TextStyle(color: Color(0xFFFFB800), fontWeight: FontWeight.w800, fontSize: 13)),
                  ]),
                ),
              ],
            ])),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _lime, foregroundColor: const Color(0xFF080C14)),
              onPressed: winner == null ? null : () {
                final sets1 = (s1e1 > s1e2 ? 1 : 0) + (s2e1 > s2e2 ? 1 : 0) +
                    (needs3 && (int.tryParse(s3e1Ctrl.text) ?? 0) > (int.tryParse(s3e2Ctrl.text) ?? 0) ? 1 : 0);
                final sets2 = (s1e2 > s1e1 ? 1 : 0) + (s2e2 > s2e1 ? 1 : 0) +
                    (needs3 && (int.tryParse(s3e2Ctrl.text) ?? 0) > (int.tryParse(s3e1Ctrl.text) ?? 0) ? 1 : 0);
                Navigator.pop(ctx, (
                  sets1: sets1, sets2: sets2,
                  s1: '$s1e1-$s1e2', s2: '$s2e1-$s2e2',
                  s3: needs3 ? '${s3e1Ctrl.text}-${s3e2Ctrl.text}' : null,
                ));
              },
              child: const Text('Confirmer'),
            ),
          ],
        );
      }),
    );

    if (result == null) return;
    await _runAction(
      () => _matchesService.submitScore(
        matchId: match.id,
        equipeId: selectedEquipeId,
        setsEquipe1: result.sets1,
        setsEquipe2: result.sets2,
        scoreSet1: result.s1,
        scoreSet2: result.s2,
        scoreSet3: result.s3,
      ),
      successMessage: 'Score saisi avec succès',
    );
  }

  Widget _buildHistoryFilters() {
    const lime = Color(0xFFC8F000);
    const cardBg = Color(0xFF0F1621);
    final results = ['Tous', 'Victoires', 'Défaites'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Barre de recherche
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: TextField(
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Rechercher une équipe, terrain...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
              prefixIcon: Icon(Icons.search_rounded, color: lime.withValues(alpha: 0.6), size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              suffixIcon: _historySearch.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded, color: Colors.white.withValues(alpha: 0.3), size: 16),
                      onPressed: () => setState(() => _historySearch = ''),
                    )
                  : null,
            ),
            onChanged: (v) => setState(() => _historySearch = v),
          ),
        ),
        const SizedBox(height: 8),
        // Chips de filtre résultat
        Row(
          children: results.map((label) {
            final selected = _historyResultFilter == label;
            Color chipColor = Colors.white.withValues(alpha: 0.4);
            if (label == 'Victoires') chipColor = lime;
            if (label == 'Défaites') chipColor = const Color(0xFFFF4757);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _historyResultFilter = label),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected ? chipColor.withValues(alpha: 0.15) : cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? chipColor : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected ? chipColor : Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMatchCard(MatchEntry match, {bool allowSubmit = false}) {
    final displayScore = match.scoreValide != null
        ? '${match.scoreValide!.setsEquipe1} - ${match.scoreValide!.setsEquipe2}'
        : 'Non renseigné';
    final statusColor = _statusColor(match.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _lime.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_teamName(match, true)} vs ${_teamName(match, false)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                ),
                child: Text(
                  _statusLabel(match.status),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip(icon: Icons.calendar_today_outlined, label: '${match.date.day.toString().padLeft(2, '0')}/${match.date.month.toString().padLeft(2, '0')}/${match.date.year}'),
              const SizedBox(width: 12),
              _InfoChip(icon: Icons.access_time_outlined, label: '${match.date.hour.toString().padLeft(2, '0')}:${match.date.minute.toString().padLeft(2, '0')}'),
            ],
          ),
          const SizedBox(height: 8),
          _InfoChip(icon: Icons.location_on_outlined, label: match.terrain, expanded: true),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _lime.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _lime.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.sports_tennis_rounded, size: 15, color: _lime.withValues(alpha: 0.8)),
                const SizedBox(width: 8),
                Text(
                  'Score : $displayScore',
                  style: TextStyle(
                    color: _lime.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (allowSubmit) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isActionLoading ? null : () => _showSubmitScoreDialog(match),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _lime,
                  side: BorderSide(color: _lime.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: const Text('Saisir le score', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          children: [
            const SizedBox(height: 120),
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 56),
            const SizedBox(height: 12),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Reessayer'),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _lime.withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                  color: _lime.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _lime.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.emoji_events_rounded, color: _lime, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _myPosition != null ? 'Classement #$_myPosition' : 'Classement indisponible',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      if (_myPosition != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '$_myPoints points',
                          style: TextStyle(
                            color: _lime.withValues(alpha: 0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Match view filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterTab(label: 'Tous', selected: _viewFilter == MatchViewFilter.all, onTap: () => setState(() => _viewFilter = MatchViewFilter.all)),
                const SizedBox(width: 8),
                _FilterTab(label: 'Programmés', selected: _viewFilter == MatchViewFilter.upcoming, onTap: () => setState(() => _viewFilter = MatchViewFilter.upcoming)),
                const SizedBox(width: 8),
                _FilterTab(label: 'Historique', selected: _viewFilter == MatchViewFilter.history, onTap: () => setState(() => _viewFilter = MatchViewFilter.history)),
                const SizedBox(width: 8),
                _FilterTab(label: 'Matchs', icon: Icons.sports_tennis_rounded, selected: _viewFilter == MatchViewFilter.matchs, onTap: () => setState(() => _viewFilter = MatchViewFilter.matchs)),
                const SizedBox(width: 8),
                _FilterTab(label: 'Tournois', icon: Icons.emoji_events_rounded, selected: _viewFilter == MatchViewFilter.tournois, onTap: () => setState(() => _viewFilter = MatchViewFilter.tournois)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _viewFilter = MatchViewFilter.history;
                    _historyResultFilter = 'Victoires';
                  }),
                  child: _StatCard(
                    title: 'Victoires',
                    value: '${_stats?.victoires ?? 0}',
                    tappable: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _viewFilter = MatchViewFilter.history;
                    _historyResultFilter = 'Défaites';
                  }),
                  child: _StatCard(
                    title: 'Défaites',
                    value: '${_stats?.defaites ?? 0}',
                    tappable: true,
                    valueColor: const Color(0xFFFF4757),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  title: 'A jouer',
                  value: '${_stats?.matchsProgrammes ?? 0}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildRecentFormCard(),
          const SizedBox(height: 14),
          _buildLevelEvolutionCard(),
          const SizedBox(height: 20),
          // ── Vue Matchs (tous les matchs réguliers) ──────────────────────
          if (_viewFilter == MatchViewFilter.matchs) ...[
            _SectionTitle(label: 'Tous les matchs'),
            const SizedBox(height: 10),
            if (_myMatches.isEmpty)
              _EmptyState(message: 'Aucun match.')
            else
              ..._myMatches.map((m) => _buildMatchCard(m,
                allowSubmit: m.status == MatchStatus.programme)),
          ]
          // ── Vue Tournois uniquement ──────────────────────────────────────
          else if (_viewFilter == MatchViewFilter.tournois) ...[
            _buildTournamentSection(),
            if (_myTournaments.isEmpty)
              _EmptyState(message: 'Aucun tournoi en cours.'),
          ]
          // ── Vue normale (Tous / Programmés / Historique) ─────────────────
          else ...[
            _SectionTitle(label: 'Mes matchs à jouer'),
            const SizedBox(height: 10),
            if (_viewFilter != MatchViewFilter.history)
              if (_upcomingMatches.isEmpty)
                _EmptyState(message: 'Aucun match programmé.')
              else
                ..._upcomingMatches.map((m) => _buildMatchCard(m, allowSubmit: true)),
            const SizedBox(height: 18),
            _SectionTitle(label: 'Historique'),
            const SizedBox(height: 10),
            if (_viewFilter != MatchViewFilter.upcoming) ...[
              _buildHistoryFilters(),
              const SizedBox(height: 10),
              if (_filteredHistoryMatches.isEmpty)
                _EmptyState(message: 'Aucun match trouvé.')
              else
                ..._filteredHistoryMatches.map((m) => _buildMatchCard(m)),
            ],
            _buildTournamentSection(),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    this.tappable = false,
    this.valueColor,
  });

  static const _lime = Color(0xFFC8F000);
  static const _cardBg = Color(0xFF0F1621);

  final String title;
  final String value;
  final bool tappable;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final color = valueColor ?? _lime;
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tappable ? color.withValues(alpha: 0.2) : _lime.withValues(alpha: 0.12),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (tappable) ...[
                const SizedBox(width: 3),
                Icon(Icons.touch_app_rounded, size: 10, color: color.withValues(alpha: 0.5)),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFFC8F000),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1621),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(width: 10),
          Text(
            message,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, this.expanded = false});

  final IconData icon;
  final String label;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.white38),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
    return expanded ? content : content;
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({required this.label, required this.selected, required this.onTap, this.icon});

  static const _lime = Color(0xFFC8F000);

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _lime.withValues(alpha: 0.15) : const Color(0xFF0F1621),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _lime.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: selected ? _lime : Colors.white.withValues(alpha: 0.4)),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? _lime : Colors.white.withValues(alpha: 0.5),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TournamentInfoChip extends StatelessWidget {
  const _TournamentInfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
