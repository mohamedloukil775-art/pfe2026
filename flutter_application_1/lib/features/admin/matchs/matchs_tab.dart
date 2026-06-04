import 'package:flutter/material.dart';

import '../../../data/services/services.dart';
import '../../../domain/domain.dart';

class MatchsTab extends StatefulWidget {
  const MatchsTab({super.key});

  @override
  State<MatchsTab> createState() => _MatchsTabState();
}

class _MatchsTabState extends State<MatchsTab> {
  static const _lime = Color(0xFFC8F000);
  static const _cardBg = Color(0xFF0F1621);
  static const int _pageSize = 15;

  final MatchesServiceMock _matchesService = MatchesServiceMock();
  final TeamsServiceMock _teamsService = TeamsServiceMock();

  List<MatchEntry> _matches = const [];
  List<Team> _teams = const [];
  String _teamSearchQuery = '';
  String _matchSearchQuery = '';
  int? _selectedTeamFilterId;
  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _error;
  MatchStatus? _selectedFilter;
  int _visibleMatches = _pageSize;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _matchesService.getAllMatches(),
        _teamsService.getAllTeams(),
      ]);

      if (!mounted) return;
      setState(() {
        _matches = results[0] as List<MatchEntry>;
        _teams = results[1] as List<Team>;
        final filteredCount = _selectedFilter == null
            ? _matches.length
            : _matches.where((m) => m.status == _selectedFilter).length;
        _visibleMatches = filteredCount < _pageSize ? filteredCount : _pageSize;
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
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

  static const List<String> _complexes = [
    'Vamos Sport', 'La Casa del Padel', 'Le Padel Sfax', 'Just Padel',
  ];

  static const List<String> _terrains = [
    'Terrain 1', 'Terrain 2', 'Terrain 3', 'Terrain 4',
  ];

  bool _sameHour(DateTime a, DateTime b) =>
      a.year == b.year &&
      a.month == b.month &&
      a.day == b.day &&
      a.hour == b.hour;

  String? _checkConflict({
    required int equipe1Id,
    required int equipe2Id,
    required String terrain,
    required String complexe,
    required DateTime date,
  }) {
    for (final m in _matches) {
      if (!_sameHour(m.date, date)) continue;
      if (m.terrain == terrain && m.complexeSportif == complexe) {
        return 'Le $terrain (${complexe}) est déjà occupé à ${date.hour}h00.';
      }
      if (m.equipe1Id == equipe1Id || m.equipe2Id == equipe1Id) {
        return '${_teamNameById(equipe1Id)} a déjà un match à ${date.hour}h00.';
      }
      if (m.equipe1Id == equipe2Id || m.equipe2Id == equipe2Id) {
        return '${_teamNameById(equipe2Id)} a déjà un match à ${date.hour}h00.';
      }
    }
    return null;
  }

  String _teamNameById(int id) {
    for (final team in _teams) {
      if (team.id == id) return team.nom;
    }
    return 'Equipe #$id';
  }

  String _teamName(MatchEntry match, bool isFirst) {
    if (isFirst) {
      return match.equipe1Nom ?? _teamNameById(match.equipe1Id);
    }
    return match.equipe2Nom ?? _teamNameById(match.equipe2Id);
  }

  List<MatchEntry> get _filteredMatches {
    var list = _matches;
    if (_selectedFilter != null) {
      list = list.where((m) => m.status == _selectedFilter).toList();
    }

    if (_selectedTeamFilterId != null) {
      list = list
          .where(
            (m) =>
                m.equipe1Id == _selectedTeamFilterId ||
                m.equipe2Id == _selectedTeamFilterId,
          )
          .toList();
    }

    if (_teamSearchQuery.trim().isNotEmpty) {
      final q = _teamSearchQuery.trim().toLowerCase();
      list = list.where((m) {
        final t1 = (m.equipe1Nom ?? _teamNameById(m.equipe1Id)).toLowerCase();
        final t2 = (m.equipe2Nom ?? _teamNameById(m.equipe2Id)).toLowerCase();
        return t1.contains(q) || t2.contains(q);
      }).toList();
    }

    final matchQuery = _matchSearchQuery.trim().toLowerCase();
    if (matchQuery.isNotEmpty) {
      list = list.where((m) {
        final team1 = (m.equipe1Nom ?? _teamNameById(m.equipe1Id)).toLowerCase();
        final team2 = (m.equipe2Nom ?? _teamNameById(m.equipe2Id)).toLowerCase();
        final terrain = m.terrain.toLowerCase();
        final date = '${m.date.day}/${m.date.month}/${m.date.year} ${m.date.hour}:${m.date.minute}'.toLowerCase();
        return team1.contains(matchQuery) ||
            team2.contains(matchQuery) ||
            terrain.contains(matchQuery) ||
            date.contains(matchQuery) ||
            _statusLabel(m.status).toLowerCase().contains(matchQuery);
      }).toList();
    }

    return list;
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }

  Widget _buildHeroMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color accent,
  }) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }

  Widget _buildInfoTag(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeBanner(DateTime dateTime) {
    final local = dateTime.toLocal();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0B1220),
            const Color(0xFF111827),
            const Color(0xFF182235),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF58D6B0).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.event_outlined, color: Color(0xFF58D6B0)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Créneau: ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeLabel(TimeOfDay time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<DateTime?> _showModernDateTimePicker({
    required DateTime initialDateTime,
  }) async {
    final now = DateTime.now();
    final dateOptions = List.generate(7, (index) {
      final date = DateTime(now.year, now.month, now.day).add(Duration(days: index));
      return date;
    });
    final timeOptions = const [
      TimeOfDay(hour: 8, minute: 0),
      TimeOfDay(hour: 9, minute: 30),
      TimeOfDay(hour: 11, minute: 0),
      TimeOfDay(hour: 13, minute: 30),
      TimeOfDay(hour: 15, minute: 0),
      TimeOfDay(hour: 17, minute: 0),
      TimeOfDay(hour: 18, minute: 30),
      TimeOfDay(hour: 20, minute: 0),
    ];

    DateTime selectedDate = DateTime(
      initialDateTime.year,
      initialDateTime.month,
      initialDateTime.day,
    );
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(initialDateTime);

    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF111827), Color(0xFF0B1220)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 54,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Choisir un créneau',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sélection rapide de la date et de l’heure du match.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Dates',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 92,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: dateOptions.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final option = dateOptions[index];
                          final selected = option.year == selectedDate.year &&
                              option.month == selectedDate.month &&
                              option.day == selectedDate.day;
                          return GestureDetector(
                            onTap: () => setSheetState(() => selectedDate = option),
                            child: Container(
                              width: 76,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: selected
                                    ? const LinearGradient(
                                        colors: [Color(0xFF58D6B0), Color(0xFF2F855A)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: selected ? null : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFF58D6B0)
                                      : Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'][option.weekday - 1],
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.78),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    option.day.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Heures',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: timeOptions.map((option) {
                        final selected = option.hour == selectedTime.hour &&
                            option.minute == selectedTime.minute;
                        return ChoiceChip(
                          label: Text(_timeLabel(option)),
                          selected: selected,
                          onSelected: (_) {
                            setSheetState(() => selectedTime = option);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    _buildDateTimeBanner(
                      DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(
                                context,
                                DateTime(
                                  selectedDate.year,
                                  selectedDate.month,
                                  selectedDate.day,
                                  selectedTime.hour,
                                  selectedTime.minute,
                                ),
                              );
                            },
                            child: const Text('Valider'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Team> _filterTeamsByQuery(
    List<Team> teams,
    String query, {
    Set<int> keepIds = const {},
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return teams;
    final prefixMatches = <Team>[];
    final containsMatches = <Team>[];

    for (final team in teams) {
      if (keepIds.contains(team.id)) {
        prefixMatches.add(team);
        continue;
      }
      final name = team.nom.toLowerCase();
      if (name.startsWith(normalizedQuery)) {
        prefixMatches.add(team);
      } else if (name.contains(normalizedQuery)) {
        containsMatches.add(team);
      }
    }

    return [...prefixMatches, ...containsMatches];
  }

  Future<void> _showScheduleDialog() async {
    if (_teams.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Il faut au moins 2 equipes pour planifier un match.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    String? terrain;
    String complexe = _complexes.first;
    int? equipe1Id;
    int? equipe2Id;
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 1));

    final schedule =
        await showDialog<
          ({int equipe1Id, int equipe2Id, String terrain, String complexe, DateTime date})
        >(
          context: context,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  title: const Text('Planifier match'),
                  content: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Autocomplete<Team>(
                            optionsBuilder: (textEditingValue) {
                              final q = textEditingValue.text
                                  .trim()
                                  .toLowerCase();
                              return _filterTeamsByQuery(
                                _teams,
                                q,
                                keepIds: {if (equipe2Id != null) equipe2Id!},
                              );
                            },
                            displayStringForOption: (Team t) => t.nom,
                            fieldViewBuilder:
                                (context, controller, focusNode, onSubmit) {
                                  if (equipe1Id != null) {
                                    final t = _teams.firstWhere(
                                      (x) => x.id == equipe1Id,
                                      orElse: () => Team(
                                        id: -1,
                                        nom: '',
                                        playerIds: const [],
                                      ),
                                    );
                                    if (t.id != -1 && controller.text.isEmpty) {
                                      controller.text = t.nom;
                                    }
                                  }
                                  return TextFormField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    decoration: const InputDecoration(
                                      labelText: 'Equipe 1',
                                      prefixIcon: Icon(Icons.search),
                                    ),
                                    validator: (_) => equipe1Id == null
                                        ? 'Choisir equipe 1'
                                        : null,
                                  );
                                },
                            onSelected: (selection) {
                              setDialogState(() => equipe1Id = selection.id);
                            },
                          ),
                          const SizedBox(height: 12),
                          Autocomplete<Team>(
                            optionsBuilder: (textEditingValue) {
                              final q = textEditingValue.text
                                  .trim()
                                  .toLowerCase();
                              return _filterTeamsByQuery(
                                _teams,
                                q,
                                keepIds: {if (equipe1Id != null) equipe1Id!},
                              );
                            },
                            displayStringForOption: (Team t) => t.nom,
                            fieldViewBuilder:
                                (context, controller, focusNode, onSubmit) {
                                  if (equipe2Id != null) {
                                    final t = _teams.firstWhere(
                                      (x) => x.id == equipe2Id,
                                      orElse: () => Team(
                                        id: -1,
                                        nom: '',
                                        playerIds: const [],
                                      ),
                                    );
                                    if (t.id != -1 && controller.text.isEmpty) {
                                      controller.text = t.nom;
                                    }
                                  }
                                  return TextFormField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    decoration: const InputDecoration(
                                      labelText: 'Equipe 2',
                                      prefixIcon: Icon(Icons.search),
                                    ),
                                    validator: (_) => equipe2Id == null
                                        ? 'Choisir equipe 2'
                                        : null,
                                  );
                                },
                            onSelected: (selection) {
                              setDialogState(() => equipe2Id = selection.id);
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Centre sportif',
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ),
                            value: complexe,
                            items: _complexes
                                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (v) => setDialogState(() => complexe = v!),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Terrain',
                              prefixIcon: Icon(Icons.sports_tennis),
                            ),
                            value: terrain,
                            items: _terrains
                                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                                .toList(),
                            onChanged: (value) => setDialogState(() => terrain = value),
                            validator: (_) => terrain == null ? 'Choisir un terrain' : null,
                          ),
                          const SizedBox(height: 12),
                          _buildDateTimeBanner(selectedDate),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await _showModernDateTimePicker(
                                initialDateTime: selectedDate,
                              );
                              if (picked == null) return;
                              setDialogState(() => selectedDate = picked);
                            },
                            icon: const Icon(Icons.edit_calendar_outlined),
                            label: const Text('Modifier date et heure'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: _isActionLoading
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    ElevatedButton(
                      onPressed: _isActionLoading
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              if (equipe1Id == equipe2Id) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Les equipes doivent etre differentes.',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              final conflict = _checkConflict(
                                equipe1Id: equipe1Id!,
                                equipe2Id: equipe2Id!,
                                terrain: terrain!,
                                complexe: complexe,
                                date: selectedDate,
                              );
                              if (conflict != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(conflict),
                                    backgroundColor: Colors.orange.shade800,
                                  ),
                                );
                                return;
                              }

                              Navigator.pop(context, (
                                equipe1Id: equipe1Id!,
                                equipe2Id: equipe2Id!,
                                terrain: terrain!,
                                complexe: complexe,
                                date: selectedDate,
                              ));
                            },
                      child: const Text('Planifier'),
                    ),
                  ],
                );
              },
            );
          },
        );

    if (schedule == null) return;

    await _runAction(
      () => _matchesService.scheduleMatch(
        date: schedule.date,
        terrain: schedule.terrain,
        complexeSportif: schedule.complexe,
        equipe1Id: schedule.equipe1Id,
        equipe2Id: schedule.equipe2Id,
      ),
      successMessage: 'Match planifie avec succes',
    );
  }

  Future<void> _showValidateScoreDialog(MatchEntry match) async {
    final formKey = GlobalKey<FormState>();
    var score1 = (match.scoreValide?.setsEquipe1 ?? 0).toString();
    var score2 = (match.scoreValide?.setsEquipe2 ?? 0).toString();

    final scores = await showDialog<({int setsEquipe1, int setsEquipe2})>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Valider score'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${_teamName(match, true)} vs ${_teamName(match, false)}'),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: score1,
                  decoration: InputDecoration(
                    labelText: _teamName(match, true),
                  ),
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
                  decoration: InputDecoration(
                    labelText: _teamName(match, false),
                  ),
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
                      Navigator.pop(context, (
                        setsEquipe1: int.parse(score1),
                        setsEquipe2: int.parse(score2),
                      ));
                    },
              child: const Text('Valider'),
            ),
          ],
        );
      },
    );

    if (scores == null) return;

    await _runAction(
      () => _matchesService.validateScore(
        matchId: match.id,
        setsEquipe1: scores.setsEquipe1,
        setsEquipe2: scores.setsEquipe2,
      ),
      successMessage: 'Score valide',
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

    final matches = _filteredMatches;
    final visibleMatches = matches.take(_visibleMatches).toList();
    final hasMore = _visibleMatches < matches.length;
    final totalMatches = _matches.length;
    final scheduledMatches = _matches.where((m) => m.status == MatchStatus.programme).length;
    final validatedMatches = _matches.where((m) => m.status == MatchStatus.valide).length;
    final enteredResults = _matches.where((m) => m.status == MatchStatus.resultatSaisi).length;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: visibleMatches.length + 1 + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF101827), Color(0xFF1B2332), Color(0xFF0B0F15)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      blurRadius: 18,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Matchs',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Planification, validation et suivi des rencontres dans une interface plus claire et plus premium.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.76),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isActionLoading ? null : _showScheduleDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _lime,
                            foregroundColor: const Color(0xFF080C14),
                          ),
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Planifier match'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildHeroMetric(
                            label: 'Total',
                            value: totalMatches.toString(),
                            icon: Icons.sports_tennis,
                            accent: const Color(0xFF58D6B0),
                          ),
                          const SizedBox(width: 10),
                          _buildHeroMetric(
                            label: 'Programmés',
                            value: scheduledMatches.toString(),
                            icon: Icons.schedule_outlined,
                            accent: const Color(0xFF5AA9FF),
                          ),
                          const SizedBox(width: 10),
                          _buildHeroMetric(
                            label: 'Résultats saisis',
                            value: enteredResults.toString(),
                            icon: Icons.edit_note_outlined,
                            accent: const Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 10),
                          _buildHeroMetric(
                            label: 'Validés',
                            value: validatedMatches.toString(),
                            icon: Icons.verified_outlined,
                            accent: const Color(0xFF8B5CF6),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Rechercher un match',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _matchSearchQuery = value;
                          final filteredCount = _filteredMatches.length;
                          _visibleMatches = filteredCount < _pageSize
                              ? filteredCount
                              : _pageSize;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: 'Tous',
                            selected: _selectedFilter == null,
                            onTap: () {
                              setState(() {
                                _selectedFilter = null;
                                _visibleMatches = _filteredMatches.length < _pageSize
                                    ? _filteredMatches.length
                                    : _pageSize;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          ...MatchStatus.values.map(
                            (status) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildFilterChip(
                                label: _statusLabel(status),
                                selected: _selectedFilter == status,
                                onTap: () {
                                  setState(() {
                                    _selectedFilter = status;
                                    _visibleMatches = _filteredMatches.length < _pageSize
                                        ? _filteredMatches.length
                                        : _pageSize;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Autocomplete<Team>(
                      optionsBuilder: (textEditingValue) {
                        final q = textEditingValue.text.trim().toLowerCase();
                        return _filterTeamsByQuery(_teams, q);
                      },
                      displayStringForOption: (Team t) => t.nom,
                      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                        controller.text = _teamSearchQuery;
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: 'Rechercher equipe',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _teamSearchQuery.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _teamSearchQuery = '';
                                        _selectedTeamFilterId = null;
                                      });
                                    },
                                  ),
                          ),
                          onChanged: (v) => setState(() => _teamSearchQuery = v),
                        );
                      },
                      onSelected: (selection) {
                        setState(() {
                          _selectedTeamFilterId = selection.id;
                          _teamSearchQuery = selection.nom;
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          if (hasMore && index == visibleMatches.length + 1) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    final next = _visibleMatches + _pageSize;
                    _visibleMatches = next > matches.length
                        ? matches.length
                        : next;
                  });
                },
                icon: const Icon(Icons.expand_more),
                label: const Text('Charger plus'),
              ),
            );
          }

          final match = visibleMatches[index - 1];
          final status = match.status;

          final displayScore = match.scoreValide != null
              ? '${match.scoreValide!.setsEquipe1} - ${match.scoreValide!.setsEquipe2}'
              : 'Non renseigné';
          final local = match.date.toLocal();
          final dateStr =
              '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
          final timeStr =
              '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _lime.withValues(alpha: 0.10)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_teamName(match, true)} vs ${_teamName(match, false)}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Chip(
                        avatar: Icon(
                          Icons.flag,
                          color: _statusColor(status),
                          size: 16,
                        ),
                        label: Text(_statusLabel(status)),
                        backgroundColor: _statusColor(status).withValues(alpha: 0.14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildInfoTag(
                        Icons.stadium_outlined,
                        match.terrain,
                        const Color(0xFF58D6B0),
                      ),
                      _buildInfoTag(
                        Icons.calendar_today_outlined,
                        dateStr,
                        const Color(0xFF5AA9FF),
                      ),
                      _buildInfoTag(
                        Icons.access_time_outlined,
                        timeStr,
                        const Color(0xFF5AA9FF),
                      ),
                      _buildInfoTag(
                        Icons.sports_score_outlined,
                        match.scoreValide != null
                            ? 'Score : $displayScore'
                            : displayScore,
                        match.scoreValide != null
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFF59E0B),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (status != MatchStatus.valide)
                        _buildActionButton(
                          label: 'Saisir résultat',
                          icon: Icons.sports_score,
                          onPressed: _isActionLoading
                              ? null
                              : () => _showValidateScoreDialog(match),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
