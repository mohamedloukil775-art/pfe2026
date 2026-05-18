import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../data/services/services.dart';
import '../../../domain/domain.dart';

class EquipesTab extends StatefulWidget {
  const EquipesTab({super.key});

  @override
  State<EquipesTab> createState() => _EquipesTabState();
}

class _EquipesTabState extends State<EquipesTab> {
  static const _lime = Color(0xFFC8F000);
  static const _cardBg = Color(0xFF0F1621);
  final TeamsServiceMock _teamsService = TeamsServiceMock();
  final PlayersServiceMock _playersService = PlayersServiceMock();

  List<Team> _teams = const [];
  List<AppUser> _players = const [];
  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _error;
  String _teamSearchQuery = '';

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
        _teamsService.getAllTeams(),
        _playersService.getAllPlayers(),
      ]);

      if (!mounted) return;
      setState(() {
        _teams = results[0] as List<Team>;
        _players = results[1] as List<AppUser>;
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

  Future<String?> _pickImagePath() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    return result?.files.single.path;
  }

  Widget _buildTeamAvatar(Team team, {double radius = 26}) {
    final path = team.photoPath;
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(path)),
      );
    }

    return CircleAvatar(
      radius: radius,
      child: Text(team.nom.isNotEmpty ? team.nom[0].toUpperCase() : '?'),
    );
  }

  Widget _buildTeamPhotoPreview(String? path) {
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          File(path),
          width: 72,
          height: 72,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(Icons.group, color: Colors.grey.shade600, size: 34),
    );
  }

  Widget _buildHeroMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
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

  List<Team> get _filteredTeams {
    final query = _teamSearchQuery.trim().toLowerCase();
    if (query.isEmpty) return _teams;

    return _teams.where((team) {
      final teamName = team.nom.toLowerCase();
      final playerNames = team.playerIds
          .map((id) => _findPlayerById(id)?.nom.toLowerCase() ?? '')
          .join(' ');
      return teamName.contains(query) || playerNames.contains(query);
    }).toList();
  }

  List<AppUser> get _activePlayers =>
      _players.where((p) => p.status == UserStatus.actif).toList();

  AppUser? _findPlayerById(int id) {
    for (final p in _players) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<AppUser> _filterPlayersByQuery(
    List<AppUser> players,
    String query, {
    Set<int> keepIds = const {},
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return players;
    // Prefix matches first (startsWith), then fallback to contains.
    final prefixMatches = <AppUser>[];
    final containsMatches = <AppUser>[];

    for (final player in players) {
      if (keepIds.contains(player.id)) {
        // keep selected players visible regardless of the query
        prefixMatches.add(player);
        continue;
      }

      final name = player.nom.toLowerCase();
      final level = player.niveau.toString();

      if (name.startsWith(normalizedQuery) ||
          level.startsWith(normalizedQuery)) {
        prefixMatches.add(player);
      } else if (name.contains(normalizedQuery) ||
          level.contains(normalizedQuery)) {
        containsMatches.add(player);
      }
    }

    return [...prefixMatches, ...containsMatches];
  }

  String _teamPlayersLabel(Team team) {
    if (team.playerIds.isEmpty) return 'Aucun joueur';
    final names = team.playerIds.map((id) {
      final player = _findPlayerById(id);
      if (player == null) return 'Joueur #$id';
      return '${player.nom} (Niv ${player.niveau})';
    }).toList();
    return names.join(' • ');
  }

  Future<void> _showCreateTeamDialog() async {
    if (_activePlayers.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Il faut au moins 2 joueurs actifs pour créer une équipe.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    String teamName = '';
    int? joueur1Id;
    int? joueur2Id;
    String? teamPhotoPath;

    final createPayload =
        await showDialog<({String nom, int joueur1Id, int joueur2Id, String? photoPath})>(
          context: context,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setDialogState) {
                final keepIds = <int>{};
                if (joueur1Id != null) keepIds.add(joueur1Id!);
                if (joueur2Id != null) keepIds.add(joueur2Id!);

                return AlertDialog(
                  title: const Text('Creer equipe'),
                  content: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Nom equipe',
                            ),
                            onChanged: (value) => teamName = value,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nom equipe requis';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildTeamPhotoPreview(teamPhotoPath),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final picked = await _pickImagePath();
                                    if (picked == null) return;
                                    setDialogState(() => teamPhotoPath = picked);
                                  },
                                  icon: const Icon(Icons.photo_library_outlined),
                                  label: const Text('Importer photo equipe'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Autocomplete<AppUser>(
                            optionsBuilder: (textEditingValue) {
                              final q = textEditingValue.text
                                  .trim()
                                  .toLowerCase();
                              return _filterPlayersByQuery(
                                _activePlayers,
                                q,
                                keepIds: {if (joueur2Id != null) joueur2Id!},
                              );
                            },
                            displayStringForOption: (AppUser p) =>
                                '${p.nom} (Niv ${p.niveau})',
                            fieldViewBuilder:
                                (context, controller, focusNode, onSubmit) {
                                  return TextFormField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    decoration: const InputDecoration(
                                      labelText: 'Joueur 1',
                                      prefixIcon: Icon(Icons.search),
                                    ),
                                    validator: (_) => joueur1Id == null
                                        ? 'Choisir joueur 1'
                                        : null,
                                  );
                                },
                            onSelected: (selection) {
                              setDialogState(() => joueur1Id = selection.id);
                            },
                          ),
                          const SizedBox(height: 12),
                          Autocomplete<AppUser>(
                            optionsBuilder: (textEditingValue) {
                              final q = textEditingValue.text
                                  .trim()
                                  .toLowerCase();
                              return _filterPlayersByQuery(
                                _activePlayers,
                                q,
                                keepIds: {if (joueur1Id != null) joueur1Id!},
                              );
                            },
                            displayStringForOption: (AppUser p) =>
                                '${p.nom} (Niv ${p.niveau})',
                            fieldViewBuilder:
                                (context, controller, focusNode, onSubmit) {
                                  return TextFormField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    decoration: const InputDecoration(
                                      labelText: 'Joueur 2',
                                      prefixIcon: Icon(Icons.search),
                                    ),
                                    validator: (_) => joueur2Id == null
                                        ? 'Choisir joueur 2'
                                        : null,
                                  );
                                },
                            onSelected: (selection) {
                              setDialogState(() => joueur2Id = selection.id);
                            },
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
                              if (joueur1Id == joueur2Id) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Les 2 joueurs doivent etre differents.',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              Navigator.pop(context, (
                                nom: teamName.trim(),
                                joueur1Id: joueur1Id!,
                                joueur2Id: joueur2Id!,
                                photoPath: teamPhotoPath,
                              ));
                            },
                      child: const Text('Creer'),
                    ),
                  ],
                );
              },
            );
          },
        );

    if (createPayload == null) return;

    await _runAction(
      () => _teamsService.createTeam(
        nom: createPayload.nom,
        joueur1Id: createPayload.joueur1Id,
        joueur2Id: createPayload.joueur2Id,
        photoPath: createPayload.photoPath,
      ),
      successMessage: 'Equipe creee avec succes',
    );
  }

  Future<void> _showEditTeamDialog(Team team) async {
    final formKey = GlobalKey<FormState>();
    String teamName = team.nom;
    int? joueur1Id = team.playerIds.isNotEmpty ? team.playerIds[0] : null;
    int? joueur2Id = team.playerIds.length > 1 ? team.playerIds[1] : null;
    String? teamPhotoPath = team.photoPath;

    final selectablePlayers = _players.where((p) {
      if (p.status == UserStatus.actif) return true;
      return team.playerIds.contains(p.id);
    }).toList();

    final updatePayload =
        await showDialog<({String nom, int joueur1Id, int joueur2Id, String? photoPath})>(
          context: context,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setDialogState) {
                final keepIds = <int>{};
                if (joueur1Id != null) keepIds.add(joueur1Id!);
                if (joueur2Id != null) keepIds.add(joueur2Id!);

                return AlertDialog(
                  title: Text('Modifier equipe: ${team.nom}'),
                  content: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            initialValue: teamName,
                            decoration: const InputDecoration(
                              labelText: 'Nom equipe',
                            ),
                            onChanged: (value) => teamName = value,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nom equipe requis';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildTeamPhotoPreview(teamPhotoPath),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final picked = await _pickImagePath();
                                    if (picked == null) return;
                                    setDialogState(() => teamPhotoPath = picked);
                                  },
                                  icon: const Icon(Icons.photo_library_outlined),
                                  label: const Text('Modifier photo equipe'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Autocomplete<AppUser>(
                            optionsBuilder: (textEditingValue) {
                              final q = textEditingValue.text
                                  .trim()
                                  .toLowerCase();
                              return _filterPlayersByQuery(
                                selectablePlayers,
                                q,
                                keepIds: {if (joueur2Id != null) joueur2Id!},
                              );
                            },
                            displayStringForOption: (AppUser p) =>
                                '${p.nom} (Niv ${p.niveau})',
                            fieldViewBuilder:
                                (context, controller, focusNode, onSubmit) {
                                  if (joueur1Id != null) {
                                    final p = _findPlayerById(joueur1Id!);
                                    if (p != null && controller.text.isEmpty) {
                                      controller.text =
                                          '${p.nom} (Niv ${p.niveau})';
                                    }
                                  }
                                  return TextFormField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    decoration: const InputDecoration(
                                      labelText: 'Joueur 1',
                                      prefixIcon: Icon(Icons.search),
                                    ),
                                    validator: (_) => joueur1Id == null
                                        ? 'Choisir joueur 1'
                                        : null,
                                  );
                                },
                            onSelected: (selection) {
                              setDialogState(() => joueur1Id = selection.id);
                            },
                          ),
                          const SizedBox(height: 12),
                          Autocomplete<AppUser>(
                            optionsBuilder: (textEditingValue) {
                              final q = textEditingValue.text
                                  .trim()
                                  .toLowerCase();
                              return _filterPlayersByQuery(
                                selectablePlayers,
                                q,
                                keepIds: {if (joueur1Id != null) joueur1Id!},
                              );
                            },
                            displayStringForOption: (AppUser p) =>
                                '${p.nom} (Niv ${p.niveau})',
                            fieldViewBuilder:
                                (context, controller, focusNode, onSubmit) {
                                  if (joueur2Id != null) {
                                    final p = _findPlayerById(joueur2Id!);
                                    if (p != null && controller.text.isEmpty) {
                                      controller.text =
                                          '${p.nom} (Niv ${p.niveau})';
                                    }
                                  }
                                  return TextFormField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    decoration: const InputDecoration(
                                      labelText: 'Joueur 2',
                                      prefixIcon: Icon(Icons.search),
                                    ),
                                    validator: (_) => joueur2Id == null
                                        ? 'Choisir joueur 2'
                                        : null,
                                  );
                                },
                            onSelected: (selection) {
                              setDialogState(() => joueur2Id = selection.id);
                            },
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
                              if (joueur1Id == joueur2Id) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Les 2 joueurs doivent etre differents.',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              Navigator.pop(context, (
                                nom: teamName.trim(),
                                joueur1Id: joueur1Id!,
                                joueur2Id: joueur2Id!,
                                photoPath: teamPhotoPath,
                              ));
                            },
                      child: const Text('Modifier'),
                    ),
                  ],
                );
              },
            );
          },
        );

    if (updatePayload == null) return;

    await _runAction(
      () => _teamsService.updateTeam(
        teamId: team.id,
        nom: updatePayload.nom,
        joueur1Id: updatePayload.joueur1Id,
        joueur2Id: updatePayload.joueur2Id,
        photoPath: updatePayload.photoPath,
      ),
      successMessage: 'Equipe modifiee avec succes',
    );
  }

  Future<void> _confirmDeleteTeam(Team team) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer equipe'),
          content: Text(
            'Supprimer ${team.nom} ? Cette action est irreversible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _runAction(
      () => _teamsService.deleteTeam(team.id),
      successMessage: 'Equipe supprimee',
    );
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

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString().padLeft(4, '0');
    return '$day/$month/$year';
  }

  Future<void> _showTeamStatsDialog(Team team) async {
    try {
      final stats = await _teamsService.getTeamStats(team.id);
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Statistiques - ${stats.nom}'),
            content: SizedBox(
              width: 640,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildStatChip(
                          'Termines',
                          stats.matchsTermines,
                          Colors.blue,
                        ),
                        _buildStatChip(
                          'Programmes',
                          stats.matchsProgrammes,
                          Colors.orange,
                        ),
                        _buildStatChip(
                          'Victoires',
                          stats.victoires,
                          Colors.green,
                        ),
                        _buildStatChip('Defaites', stats.defaites, Colors.red),
                        _buildStatChip('Nuls', stats.nuls, Colors.deepOrange),
                        _buildStatChip(
                          'Forfaits',
                          stats.forfaits,
                          Colors.purple,
                        ),
                        _buildStatChip(
                          'Points',
                          stats.pointsTotal,
                          Colors.teal,
                        ),
                        _buildStatChip(
                          'Diff sets',
                          stats.diffSets,
                          Colors.indigo,
                        ),
                        _buildStatChip(
                          'Taux victoire',
                          '${stats.tauxVictoire.toStringAsFixed(1)}%',
                          Colors.brown,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Derniers matchs',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (stats.recentMatches.isEmpty)
                      const Text('Aucun match disponible pour cette equipe.')
                    else
                      ...stats.recentMatches.map(
                        (match) => Card(
                          child: ListTile(
                            title: Text(
                              '${match.equipe1Nom ?? 'Equipe #${match.equipe1Id}'} vs ${match.equipe2Nom ?? 'Equipe #${match.equipe2Id}'}',
                            ),
                            subtitle: Text(
                              '${_formatDate(match.date)} • ${match.terrain}',
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  match.scoreValide != null
                                      ? '${match.scoreValide!.setsEquipe1} - ${match.scoreValide!.setsEquipe2}'
                                      : 'N/A',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Chip(
                                  label: Text(_statusLabel(match.status)),
                                  backgroundColor: _statusColor(
                                    match.status,
                                  ).withValues(alpha: 0.15),
                                  labelStyle: TextStyle(
                                    color: _statusColor(match.status),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('ApiException: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStatChip(String label, Object value, Color color) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: color.withValues(alpha: 0.12),
      labelStyle: TextStyle(color: color),
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

    final teams = _filteredTeams;
    final totalTeams = _teams.length;
    final activePlayers = _activePlayers.length;
    final teamsWithPhoto = _teams.where((team) => team.photoPath != null && team.photoPath!.isNotEmpty).length;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: teams.isEmpty ? 2 : teams.length + 1,
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
                                'Équipes',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Paires, photos et joueurs associés dans une vue plus premium et lisible.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.76),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isActionLoading ? null : _showCreateTeamDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _lime,
                            foregroundColor: const Color(0xFF080C14),
                          ),
                          icon: const Icon(Icons.group_add),
                          label: const Text('Créer équipe'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildHeroMetric(
                          label: 'Équipes',
                          value: totalTeams.toString(),
                          icon: Icons.groups_2_outlined,
                          accent: const Color(0xFF58D6B0),
                        ),
                        _buildHeroMetric(
                          label: 'Joueurs actifs',
                          value: activePlayers.toString(),
                          icon: Icons.person_outline,
                          accent: const Color(0xFF5AA9FF),
                        ),
                        _buildHeroMetric(
                          label: 'Avec photo',
                          value: teamsWithPhoto.toString(),
                          icon: Icons.photo_library_outlined,
                          accent: const Color(0xFFF59E0B),
                        ),
                        _buildHeroMetric(
                          label: 'Résultats filtrés',
                          value: teams.length.toString(),
                          icon: Icons.filter_alt_outlined,
                          accent: const Color(0xFF8B5CF6),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Rechercher équipe ou joueur',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _teamSearchQuery = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          if (teams.isEmpty) {
            return const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Aucune equipe correspondante.'),
              ),
            );
          }

          final team = teams[index - 1];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _lime.withValues(alpha: 0.10)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTeamAvatar(team, radius: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              team.nom,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF58D6B0).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${team.playerIds.length} joueurs',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _teamPlayersLabel(team),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildActionButton(
                            label: 'Stats',
                            icon: Icons.bar_chart_outlined,
                            onPressed: _isActionLoading
                                ? null
                                : () => _showTeamStatsDialog(team),
                          ),
                          _buildActionButton(
                            label: 'Modifier',
                            icon: Icons.edit_outlined,
                            onPressed: _isActionLoading
                                ? null
                                : () => _showEditTeamDialog(team),
                          ),
                          _buildActionButton(
                            label: 'Supprimer',
                            icon: Icons.delete_outline,
                            onPressed: _isActionLoading
                                ? null
                                : () => _confirmDeleteTeam(team),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
