import 'package:flutter/material.dart';

import '../../../data/services/services.dart';
import '../../../domain/domain.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  static const _lime   = Color(0xFFC8F000);
  static const _cardBg = Color(0xFF0F1621);

  static const _centres = [
    'Vamos Sport',
    'La Casa del Padel',
    'Le Padel Sfax',
    'Just Padel',
  ];

  static const _centreIcons = [
    Icons.sports_tennis_rounded,
    Icons.home_rounded,
    Icons.location_city_rounded,
    Icons.place_rounded,
  ];

  static const _centreColors = [
    Color(0xFF00C8FF),
    Color(0xFFC8F000),
    Color(0xFFFF6B35),
    Color(0xFFB16BFF),
  ];

  // Time slots shown: 08h to 22h
  static const _hourStart = 8;
  static const _hourEnd   = 22;
  static final _hours = List.generate(_hourEnd - _hourStart + 1, (i) => _hourStart + i);

  final MatchesServiceMock     _matchesSvc     = MatchesServiceMock();
  final TournamentsServiceMock _tournamentsSvc = TournamentsServiceMock();
  final TeamsServiceMock       _teamsSvc       = TeamsServiceMock();
  final PlayersServiceMock     _playersSvc     = PlayersServiceMock();

  // reservation key: "$centre|$terrainNum|$hour" → label
  Map<String, String> _reservations = {};

  List<AppUser> _allPlayers = [];
  List<Team>    _allTeams   = [];

  bool _loading = true;
  DateTime _selectedDay = DateTime.now();
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _weekStart = _mondayOf(DateTime.now());
    _load();
  }

  DateTime _mondayOf(DateTime d) =>
      DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  int _parseTerrainNum(String terrain) =>
      int.tryParse(terrain.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _matchesSvc.getAllMatches(),
        _tournamentsSvc.getAllTournaments(),
        _teamsSvc.getAllTeams(),
        _playersSvc.getAllPlayers(),
      ]);

      final matches     = results[0] as List<MatchEntry>;
      final tournaments = results[1] as List<Tournament>;
      _allTeams         = results[2] as List<Team>;
      _allPlayers       = results[3] as List<AppUser>;

      final res = <String, String>{};

      // Regular matches
      for (final m in matches) {
        if (!_isSameDay(m.date.toLocal(), _selectedDay)) continue;
        final h = m.date.toLocal().hour;
        final tNum = _parseTerrainNum(m.terrain);
        final key = '${m.complexeSportif}|$tNum|$h';
        final n1 = m.equipe1Nom ?? _teamName(m.equipe1Id);
        final n2 = m.equipe2Nom ?? _teamName(m.equipe2Id);
        res[key] = '$n1 vs $n2';
      }

      // Tournament matches
      for (final t in tournaments) {
        for (final tm in t.matches) {
          if (tm.joueur1 <= 0 && tm.joueur2 <= 0) continue;
          final hour = int.tryParse(tm.heureDebut.split(':').first) ?? 0;
          if (hour < _hourStart || hour > _hourEnd) continue;
          // Use tournament date for all matches (individual matchDate not yet modelled)
          if (!_isSameDay(t.date.toLocal(), _selectedDay)) continue;
          final key = '${tm.complexeSportif}|${tm.terrainNumero}|$hour';
          final n1 = t.isTeamMode ? _teamName(tm.joueur1) : _playerName(tm.joueur1);
          final n2 = t.isTeamMode ? _teamName(tm.joueur2) : _playerName(tm.joueur2);
          res[key] = '${t.nom}: $n1 vs $n2';
        }
      }

      setState(() {
        _reservations = res;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  String _teamName(int id) {
    try { return _allTeams.firstWhere((t) => t.id == id).nom; } catch (_) { return 'Éq.$id'; }
  }

  String _playerName(int id) {
    try { return _allPlayers.firstWhere((p) => p.id == id).nom; } catch (_) { return 'J.$id'; }
  }

  bool _isReserved(String centre, int terrain, int hour) =>
      _reservations.containsKey('$centre|$terrain|$hour');

  String _label(String centre, int terrain, int hour) =>
      _reservations['$centre|$terrain|$hour'] ?? '';

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildWeekNav(),
          _buildDayChips(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _lime))
                : _buildGrid(),
          ),
        ],
      ),
    );
  }

  // ── Week navigation ───────────────────────────────────────────────────────

  Widget _buildWeekNav() {
    final endOfWeek = _weekStart.add(const Duration(days: 6));
    final label =
        '${_dayNum(_weekStart)} ${_monthShort(_weekStart.month)} – '
        '${_dayNum(endOfWeek)} ${_monthShort(endOfWeek.month)} ${endOfWeek.year}';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        children: [
          // Title
          const Icon(Icons.grid_view_rounded, color: _lime, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Disponibilité Terrains',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
          ),
          // Week nav
          _weekNavBtn(Icons.chevron_left, () {
            setState(() {
              _weekStart = _weekStart.subtract(const Duration(days: 7));
              _selectedDay = _weekStart;
            });
            _load();
          }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          _weekNavBtn(Icons.chevron_right, () {
            setState(() {
              _weekStart = _weekStart.add(const Duration(days: 7));
              _selectedDay = _weekStart;
            });
            _load();
          }),
          const SizedBox(width: 8),
          // Today button
          GestureDetector(
            onTap: () {
              setState(() {
                _weekStart   = _mondayOf(DateTime.now());
                _selectedDay = DateTime.now();
              });
              _load();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _lime.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _lime.withValues(alpha: 0.35)),
              ),
              child: const Text("Aujourd'hui",
                  style: TextStyle(color: _lime, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 8),
          // Refresh
          GestureDetector(
            onTap: _load,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.refresh_rounded, color: Colors.white54, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _weekNavBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, color: Colors.white60, size: 18),
    ),
  );

  // ── Day chips ─────────────────────────────────────────────────────────────

  Widget _buildDayChips() {
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final today = DateTime.now();

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: List.generate(7, (i) {
          final day = _weekStart.add(Duration(days: i));
          final isSelected = _isSameDay(day, _selectedDay);
          final isToday    = _isSameDay(day, today);
          final isPast     = day.isBefore(DateTime(today.year, today.month, today.day));

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedDay = day);
                _load();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _lime.withValues(alpha: 0.18)
                      : isToday
                          ? Colors.white.withValues(alpha: 0.07)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? _lime.withValues(alpha: 0.5)
                        : isToday
                            ? Colors.white.withValues(alpha: 0.18)
                            : Colors.white.withValues(alpha: 0.06),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(days[i],
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? _lime : (isPast ? Colors.white30 : Colors.white54),
                        )),
                    const SizedBox(height: 2),
                    Text('${day.day}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? _lime : (isPast ? Colors.white24 : Colors.white70),
                        )),
                    if (isToday)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 4, height: 4,
                        decoration: const BoxDecoration(
                          color: _lime, shape: BoxShape.circle),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Main grid ─────────────────────────────────────────────────────────────

  Widget _buildGrid() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      itemCount: _centres.length,
      itemBuilder: (_, ci) => _buildCentreCard(ci),
    );
  }

  Widget _buildCentreCard(int ci) {
    final centre = _centres[ci];
    final color  = _centreColors[ci];
    final icon   = _centreIcons[ci];

    // Count reservations for this centre on selected day
    int reserved = 0;
    for (int t = 1; t <= 4; t++) {
      for (final h in _hours) {
        if (_isReserved(centre, t, h)) reserved++;
      }
    }
    final total = 4 * _hours.length;
    final libre = total - reserved;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Centre header ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(centre,
                    style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14)),
              ),
              _statBadge('$libre libre', Colors.green.shade400),
              const SizedBox(width: 6),
              _statBadge('$reserved réservé', Colors.red.shade400),
            ]),
          ),
          // ── Grid table (horizontal scroll) ────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: _buildCentreTable(centre, color),
          ),
        ],
      ),
    );
  }

  Widget _statBadge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
  );

  Widget _buildCentreTable(String centre, Color centreColor) {
    const rowH    = 36.0;
    const headerH = 28.0;
    const labelW  = 52.0;
    const cellW   = 46.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Hour header row ─────────────────────────────────────────────
        Row(children: [
          SizedBox(width: labelW), // spacer for terrain label column
          ..._hours.map((h) => SizedBox(
            width: cellW, height: headerH,
            child: Center(
              child: Text(
                '${h.toString().padLeft(2, '0')}h',
                style: const TextStyle(
                    color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w700),
              ),
            ),
          )),
        ]),
        // ── Terrain rows ────────────────────────────────────────────────
        ...List.generate(4, (ti) {
          final terrainNum = ti + 1;
          return SizedBox(
            height: rowH,
            child: Row(
              children: [
                // Terrain label
                SizedBox(
                  width: labelW,
                  child: Text(
                    'T$terrainNum',
                    style: TextStyle(
                        color: centreColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800),
                  ),
                ),
                // Hour cells
                ..._hours.map((h) {
                  final reserved = _isReserved(centre, terrainNum, h);
                  final label    = reserved ? _label(centre, terrainNum, h) : '';
                  return _buildCell(reserved, label, cellW, rowH);
                }),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCell(bool reserved, String label, double w, double h) {
    return GestureDetector(
      onTap: reserved
          ? () => _showReservationInfo(label)
          : null,
      child: Container(
        width: w,
        height: h,
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        decoration: BoxDecoration(
          color: reserved
              ? Colors.red.shade900.withValues(alpha: 0.55)
              : Colors.green.shade900.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: reserved
                ? Colors.red.shade600.withValues(alpha: 0.5)
                : Colors.green.shade700.withValues(alpha: 0.3),
          ),
        ),
        child: Center(
          child: Icon(
            reserved ? Icons.lock_rounded : Icons.check_rounded,
            size: 13,
            color: reserved ? Colors.red.shade300 : Colors.green.shade400,
          ),
        ),
      ),
    );
  }

  void _showReservationInfo(String label) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.sports_tennis_rounded, color: _lime, size: 20),
          SizedBox(width: 8),
          Text('Terrain réservé', style: TextStyle(color: Colors.white, fontSize: 15)),
        ]),
        content: Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: _lime)),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _monthShort(int m) => const [
    '', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
    'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc',
  ][m];

  String _dayNum(DateTime d) => d.day.toString();
}
