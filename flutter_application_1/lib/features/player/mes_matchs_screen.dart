import 'package:flutter/material.dart';

import '../../data/services/services.dart';
import '../../domain/domain.dart';

enum MatchViewFilter { all, upcoming, history }

class MesMatchsScreen extends StatefulWidget {
  const MesMatchsScreen({super.key, required this.userId, this.teamId});

  final int userId;
  final int? teamId;

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant MesMatchsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.teamId != widget.teamId) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final teamIds = widget.teamId != null ? [widget.teamId!] : <int>[];
      final results = await Future.wait([
        _matchesService.getMyMatches(teamId: widget.teamId),
        _standingsService.getStandings(),
        _playersService.getPlayerStats(widget.userId, teamId: widget.teamId),
        _playersService.getLevelHistory(widget.userId),
        _tournamentService.getTournamentsForPlayer(widget.userId, teamIds: teamIds),
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

  String _statusLabel(MatchStatus status) {
    switch (status) {
      case MatchStatus.programme:
        return 'Programme';
      case MatchStatus.resultatSaisi:
        return 'Resultat saisi';
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

  String _myTeamName(MatchEntry match) {
    if (match.myEquipeId == match.equipe1Id) {
      return _teamName(match, true);
    }
    if (match.myEquipeId == match.equipe2Id) {
      return _teamName(match, false);
    }
    return _teamNameById(match.myEquipeId ?? 0);
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

  List<TournamentMatch> _getPlayerMatchesInTournament(Tournament t) {
    if (t.isTeamMode) {
      final tid = widget.teamId;
      if (tid == null) return [];
      return t.matches.where((m) => m.joueur1 == tid || m.joueur2 == tid).toList();
    }
    return t.matches
        .where((m) => m.joueur1 == widget.userId || m.joueur2 == widget.userId)
        .toList();
  }

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
    final myMatches = _getPlayerMatchesInTournament(t);
    const gold = Color(0xFFFFB800);
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
          const SizedBox(height: 10),
          if (myMatches.isEmpty)
            Text('Pas encore de matchs',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4), fontSize: 13))
          else
            ...myMatches.map((m) => _buildTournamentMatchRow(t, m)),
        ],
      ),
    );
  }

  Widget _buildTournamentMatchRow(Tournament t, TournamentMatch m) {
    final myId = t.isTeamMode ? (widget.teamId ?? widget.userId) : widget.userId;
    final opponentId = m.joueur1 == myId ? m.joueur2 : m.joueur1;
    final hasResult = m.vainqueur != null && m.vainqueur! > 0;
    final iWon = hasResult && m.vainqueur == myId;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: iWon
            ? Colors.green.withValues(alpha: 0.08)
            : (hasResult
                ? Colors.red.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.04)),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: iWon
              ? Colors.green.withValues(alpha: 0.25)
              : (hasResult
                  ? Colors.red.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFFFB800).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(_roundLabel(m.round),
              style: const TextStyle(
                  color: Color(0xFFFFB800), fontSize: 10, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'vs ${_participantName(t, opponentId)}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        if (hasResult)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: iWon
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              iWon ? 'V' : 'D',
              style: TextStyle(
                  color: iWon ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w800,
                  fontSize: 13),
            ),
          )
        else
          Text(
            opponentId == 0 ? '...' : 'À venir',
            style:
                TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
          ),
      ]),
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
        const SnackBar(
          content: Text('Impossible de determiner votre equipe pour ce match.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    var score1 = '0';
    var score2 = '0';
    final selectedEquipeId = match.myEquipeId!;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Saisir score'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${_teamName(match, true)} vs ${_teamName(match, false)}'),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Mon equipe: ${_myTeamName(match)}'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: score1,
                  decoration: InputDecoration(labelText: _teamName(match, true)),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => score1 = value,
                  validator: (value) {
                    final parsed = int.tryParse(value ?? '');
                    if (parsed == null || parsed < 0) return 'Score invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: score2,
                  decoration: InputDecoration(labelText: _teamName(match, false)),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => score2 = value,
                  validator: (value) {
                    final parsed = int.tryParse(value ?? '');
                    if (parsed == null || parsed < 0) return 'Score invalide';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isActionLoading ? null : () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: _isActionLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      final navigator = Navigator.of(context);
                      navigator.pop();

                      await _runAction(
                        () => _matchesService.submitScore(
                          matchId: match.id,
                          equipeId: selectedEquipeId,
                          setsEquipe1: int.parse(score1),
                          setsEquipe2: int.parse(score2),
                        ),
                        successMessage: 'Score saisi avec succes',
                      );
                    },
              child: const Text('Envoyer'),
            ),
          ],
        );
      },
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
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Victoires',
                  value: '${_stats?.victoires ?? 0}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  title: 'Taux',
                  value: '${((_stats?.tauxVictoire ?? 0) * 100).toStringAsFixed(1)}%',
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
          if (_viewFilter != MatchViewFilter.upcoming)
            if (_historyMatches.isEmpty)
              _EmptyState(message: 'Aucun historique disponible.')
            else
              ..._historyMatches.map((m) => _buildMatchCard(m)),
          _buildTournamentSection(),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});

  static const _lime = Color(0xFFC8F000);
  static const _cardBg = Color(0xFF0F1621);

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _lime.withValues(alpha: 0.12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: _lime,
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
  const _FilterTab({required this.label, required this.selected, required this.onTap});

  static const _lime = Color(0xFFC8F000);

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _lime.withValues(alpha: 0.15) : const Color(0xFF0F1621),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _lime.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? _lime : Colors.white.withValues(alpha: 0.5),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
