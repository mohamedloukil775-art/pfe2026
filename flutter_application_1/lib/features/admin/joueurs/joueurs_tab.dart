import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../data/services/services.dart';
import '../../../domain/domain.dart';

class JoueursTab extends StatefulWidget {
  const JoueursTab({super.key});

  @override
  State<JoueursTab> createState() => _JoueursTabState();
}

class _JoueursTabState extends State<JoueursTab> {
  static const _lime = Color(0xFFC8F000);
  static const _cardBg = Color(0xFF0F1621);
  static const int _pageSize = 15;

  // Use mock service when backend is not available
  final _playersService = PlayersServiceMock();

  List<AppUser> _players = const [];
  int _visiblePlayers = _pageSize;
  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _error;
  String _searchQuery = '';
  UserStatus? _statusFilter;
  String _categoryFilter = 'Tous';

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final players = await _playersService.getAllPlayers();
      if (!mounted) return;
      setState(() {
        _players = players;
        _visiblePlayers = players.length < _pageSize
            ? players.length
            : _pageSize;
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

  List<AppUser> get _filteredPlayers {
    var list = _players;
    if (_statusFilter != null) {
      list = list.where((p) => p.status == _statusFilter).toList();
    }

    if (_categoryFilter != 'Tous') {
      list = list.where((p) => p.categorieNiveau == _categoryFilter).toList();
    }

    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((p) {
        return p.nom.toLowerCase().contains(query) ||
            p.email.toLowerCase().contains(query) ||
            p.niveau.toString().contains(query);
      }).toList();
    }

    return list;
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
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

  Widget _buildPlayerAction({
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
      await _loadPlayers();
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

  Widget _buildPlayerAvatar(AppUser player, {double radius = 28}) {
    final path = player.photoPath;
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(path)),
      );
    }

    return CircleAvatar(
      radius: radius,
      child: Text(
        player.nom.isNotEmpty ? player.nom[0].toUpperCase() : '?',
      ),
    );
  }

  Future<void> _showAddPlayerDialog() async {
    final formKey = GlobalKey<FormState>();
    String nom = '';
    String email = '';
    String password = '';
    int selectedNiveau = 1;
    String? selectedPhotoPath;

    final result =
        await showDialog<
          ({String nom, String email, String password, int niveau, String? photoPath})
        >(
          context: context,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  title: const Text('Ajouter joueur'),
                  content: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            decoration: const InputDecoration(labelText: 'Nom'),
                            onChanged: (value) => nom = value,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nom requis';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildPhotoPreview(selectedPhotoPath),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final picked = await _pickImagePath();
                                    if (picked == null) return;
                                    setDialogState(
                                      () => selectedPhotoPath = picked,
                                    );
                                  },
                                  icon: const Icon(Icons.photo_library_outlined),
                                  label: const Text('Importer photo'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Email',
                            ),
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (value) => email = value,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email requis';
                              }
                              if (!value.contains('@')) {
                                return 'Email invalide';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Mot de passe',
                            ),
                            obscureText: true,
                            onChanged: (value) => password = value,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Mot de passe requis';
                              }
                              if (value.length < 6) {
                                return 'Minimum 6 caractères';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            initialValue: selectedNiveau,
                            decoration: const InputDecoration(
                              labelText: 'Niveau',
                            ),
                            items: List.generate(
                              10,
                              (index) => DropdownMenuItem<int>(
                                value: index + 1,
                                child: Text('Niveau ${index + 1}'),
                              ),
                            ),
                            onChanged: (value) {
                              if (value == null) return;
                              setDialogState(() => selectedNiveau = value);
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
                              Navigator.pop(context, (
                                nom: nom.trim(),
                                email: email.trim(),
                                password: password,
                                niveau: selectedNiveau,
                                photoPath: selectedPhotoPath,
                              ));
                            },
                      child: const Text('Ajouter'),
                    ),
                  ],
                );
              },
            );
          },
        );

    if (result == null) return;

    await _runAction(
      () => _playersService.createPlayer(
        nom: result.nom,
        email: result.email,
        password: result.password,
        niveau: result.niveau,
        photoPath: result.photoPath,
      ),
      successMessage: 'Joueur ajouté avec succès',
    );
  }

  Widget _buildPhotoPreview(String? path) {
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
      child: Icon(Icons.person, color: Colors.grey.shade600, size: 34),
    );
  }

  Future<void> _showUpdateLevelDialog(AppUser player) async {
    int selectedNiveau = player.niveau;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Modifier niveau - ${player.nom}'),
              content: DropdownButtonFormField<int>(
                initialValue: selectedNiveau,
                decoration: const InputDecoration(labelText: 'Nouveau niveau'),
                items: List.generate(
                  10,
                  (index) => DropdownMenuItem<int>(
                    value: index + 1,
                    child: Text('Niveau ${index + 1}'),
                  ),
                ),
                onChanged: (value) {
                  if (value == null) return;
                  setDialogState(() => selectedNiveau = value);
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Mettre à jour'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    await _runAction(
      () => _playersService.updatePlayerLevel(player.id, selectedNiveau),
      successMessage: 'Niveau mis à jour',
    );
  }

  Future<void> _confirmAndRun({
    required String title,
    required String message,
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    await _runAction(action, successMessage: successMessage);
  }

  Future<void> _showRecordTestDialog(AppUser player) async {
    DateTime dateTest = DateTime.now();
    int selectedNiveau = player.niveau;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Enregistrer test - ${player.nom}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: selectedNiveau,
                    decoration: const InputDecoration(
                      labelText: 'Niveau attribué',
                    ),
                    items: List.generate(
                      10,
                      (i) => DropdownMenuItem<int>(
                        value: i + 1,
                        child: Text('Niveau ${i + 1}'),
                      ),
                    ),
                    onChanged: (v) {
                      if (v == null) return;
                      setDialogState(() => selectedNiveau = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Date: ${dateTest.day.toString().padLeft(2, '0')}/${dateTest.month.toString().padLeft(2, '0')}/${dateTest.year}',
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_calendar),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                            initialDate: dateTest,
                          );
                          if (picked == null) return;
                          setDialogState(
                            () => dateTest = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) return;

    await _runAction(
      () => _playersService.addLevelTest(
        player.id,
        dateTest: dateTest,
        scoreTest: 0,
        niveauAttribue: selectedNiveau,
      ),
      successMessage: 'Test enregistré',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _loadPlayers,
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
                onPressed: _loadPlayers,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ),
          ],
        ),
      );
    }

    final visiblePlayers = _filteredPlayers.take(_visiblePlayers).toList();
    final hasMore = _visiblePlayers < _filteredPlayers.length;
    final totalPlayers = _players.length;
    final activePlayers = _players.where((p) => p.status == UserStatus.actif).length;
    final blockedPlayers = _players.where((p) => p.status == UserStatus.bloque).length;
    final averageLevel = _players.isEmpty
        ? 0.0
        : _players.map((p) => p.niveau).reduce((a, b) => a + b) / _players.length;

    return RefreshIndicator(
      onRefresh: _loadPlayers,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: visiblePlayers.length + 1 + (hasMore ? 1 : 0),
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
                                'Joueurs',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Suivi des niveaux, photos et tests de validation dans un espace clair et moderne.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.76),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isActionLoading ? null : _showAddPlayerDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _lime,
                            foregroundColor: const Color(0xFF080C14),
                          ),
                          icon: const Icon(Icons.person_add),
                          label: const Text('Ajouter joueur'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildHeroMetric(
                          label: 'Total',
                          value: totalPlayers.toString(),
                          icon: Icons.groups_2_outlined,
                          accent: const Color(0xFF58D6B0),
                        ),
                        _buildHeroMetric(
                          label: 'Affichés',
                          value: _filteredPlayers.length.toString(),
                          icon: Icons.filter_alt_outlined,
                          accent: const Color(0xFF5AA9FF),
                        ),
                        _buildHeroMetric(
                          label: 'Actifs',
                          value: activePlayers.toString(),
                          icon: Icons.verified_user_outlined,
                          accent: const Color(0xFFF59E0B),
                        ),
                        _buildHeroMetric(
                          label: 'Bloqués',
                          value: blockedPlayers.toString(),
                          icon: Icons.lock_outline,
                          accent: const Color(0xFFEF4444),
                        ),
                        _buildHeroMetric(
                          label: 'Niveau moyen',
                          value: averageLevel.toStringAsFixed(1),
                          icon: Icons.stacked_line_chart_outlined,
                          accent: const Color(0xFF8B5CF6),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Rechercher joueur',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          _visiblePlayers = _filteredPlayers.length < _pageSize
                              ? _filteredPlayers.length
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
                            selected: _statusFilter == null && _categoryFilter == 'Tous',
                            onSelected: () {
                              setState(() {
                                _statusFilter = null;
                                _categoryFilter = 'Tous';
                                _visiblePlayers = _filteredPlayers.length < _pageSize
                                    ? _filteredPlayers.length
                                    : _pageSize;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Actifs',
                            selected: _statusFilter == UserStatus.actif,
                            onSelected: () {
                              setState(() {
                                _statusFilter = UserStatus.actif;
                                _visiblePlayers = _filteredPlayers.length < _pageSize
                                    ? _filteredPlayers.length
                                    : _pageSize;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Bloqués',
                            selected: _statusFilter == UserStatus.bloque,
                            onSelected: () {
                              setState(() {
                                _statusFilter = UserStatus.bloque;
                                _visiblePlayers = _filteredPlayers.length < _pageSize
                                    ? _filteredPlayers.length
                                    : _pageSize;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Débutant',
                            selected: _categoryFilter == 'Débutant',
                            onSelected: () {
                              setState(() {
                                _categoryFilter = 'Débutant';
                                _visiblePlayers = _filteredPlayers.length < _pageSize
                                    ? _filteredPlayers.length
                                    : _pageSize;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Intermédiaire',
                            selected: _categoryFilter == 'Intermédiaire',
                            onSelected: () {
                              setState(() {
                                _categoryFilter = 'Intermédiaire';
                                _visiblePlayers = _filteredPlayers.length < _pageSize
                                    ? _filteredPlayers.length
                                    : _pageSize;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Avancé',
                            selected: _categoryFilter == 'Avancé',
                            onSelected: () {
                              setState(() {
                                _categoryFilter = 'Avancé';
                                _visiblePlayers = _filteredPlayers.length < _pageSize
                                    ? _filteredPlayers.length
                                    : _pageSize;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Expert',
                            selected: _categoryFilter == 'Expert',
                            onSelected: () {
                              setState(() {
                                _categoryFilter = 'Expert';
                                _visiblePlayers = _filteredPlayers.length < _pageSize
                                    ? _filteredPlayers.length
                                    : _pageSize;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (hasMore && index == visiblePlayers.length + 1) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    final next = _visiblePlayers + _pageSize;
                    _visiblePlayers = next > _filteredPlayers.length
                        ? _filteredPlayers.length
                        : next;
                  });
                },
                icon: const Icon(Icons.expand_more),
                label: const Text('Charger plus'),
              ),
            );
          }

          final player = visiblePlayers[index - 1];
          final isBlocked = player.status == UserStatus.bloque;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _lime.withValues(alpha: 0.10)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildPlayerAvatar(player, radius: 24),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              player.nom,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              player.email,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.72),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Chip(
                        label: Text(isBlocked ? 'Bloqué' : 'Actif'),
                        avatar: Icon(
                          isBlocked ? Icons.block : Icons.check_circle,
                          size: 16,
                          color: isBlocked ? Colors.redAccent : const Color(0xFF58D6B0),
                        ),
                        backgroundColor: (isBlocked
                                ? Colors.redAccent
                                : const Color(0xFF58D6B0))
                            .withValues(alpha: 0.12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip(
                        label: 'Niveau ${player.niveau}',
                        selected: false,
                        onSelected: () {},
                      ),
                      _buildFilterChip(
                        label: player.categorieNiveau,
                        selected: false,
                        onSelected: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPlayerAction(
                        label: 'Niveau',
                        icon: Icons.trending_up,
                        onPressed: _isActionLoading
                            ? null
                            : () => _showUpdateLevelDialog(player),
                      ),
                      _buildPlayerAction(
                        label: 'Test',
                        icon: Icons.fact_check,
                        onPressed: _isActionLoading
                            ? null
                            : () => _showRecordTestDialog(player),
                      ),
                      _buildPlayerAction(
                        label: isBlocked ? 'Débloquer' : 'Bloquer',
                        icon: isBlocked ? Icons.lock_open : Icons.block,
                        onPressed: _isActionLoading
                            ? null
                            : () => _confirmAndRun(
                                title: isBlocked
                                    ? 'Débloquer joueur'
                                    : 'Bloquer joueur',
                                message: isBlocked
                                    ? 'Débloquer ${player.nom} ?'
                                    : 'Bloquer ${player.nom} ?',
                                action: isBlocked
                                    ? () => _playersService.unblockPlayer(
                                        player.id,
                                      )
                                    : () => _playersService.blockPlayer(
                                        player.id,
                                      ),
                                successMessage: isBlocked
                                    ? 'Joueur débloqué'
                                    : 'Joueur bloqué',
                              ),
                      ),
                      _buildPlayerAction(
                        label: 'Supprimer',
                        icon: Icons.delete_outline,
                        onPressed: _isActionLoading
                            ? null
                            : () => _confirmAndRun(
                                title: 'Supprimer joueur',
                                message:
                                    'Supprimer ${player.nom} ? Cette action est irréversible.',
                                action: () =>
                                    _playersService.deletePlayer(player.id),
                                successMessage: 'Joueur supprimé',
                              ),
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
