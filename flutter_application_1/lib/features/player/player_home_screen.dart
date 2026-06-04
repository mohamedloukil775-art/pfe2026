import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../data/services/services.dart';
import '../../domain/domain.dart';
import '../../core/storage/mock_persistence.dart';
import '../auth/login_screen.dart';
import 'mes_matchs_screen.dart';
import 'mon_equipe_screen.dart';
import 'player_profile_screen.dart';

class PlayerHomeScreen extends StatefulWidget {
  final int userId;

  const PlayerHomeScreen({super.key, required this.userId});

  @override
  State<PlayerHomeScreen> createState() => _PlayerHomeScreenState();
}

class _PlayerHomeScreenState extends State<PlayerHomeScreen> {
  static const _lime = Color(0xFFC8F000);
  static const _darkBg = Color(0xFF080C14);
  static const _cardBg = Color(0xFF0F1621);

  final _authService = AuthService();
  final PlayersServiceMock _playersService = PlayersServiceMock();
  final TeamsServiceMock _teamsService = TeamsServiceMock();

  AppUser? _player;
  List<int> _myTeamIds = [];
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPlayer();
  }

  Future<void> _loadPlayer() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _playersService.getAllPlayers(),
        _teamsService.getAllTeams(),
      ]);
      final allPlayers = results[0] as List<AppUser>;
      final allTeams = results[1] as List<Team>;

      AppUser? p;
      try {
        p = allPlayers.firstWhere((e) => e.id == widget.userId);
      } catch (_) {
        p = null;
      }

      final myTeamIds = allTeams
          .where((t) => t.playerIds.contains(widget.userId))
          .map((t) => t.id)
          .toList();

      if (!mounted) return;
      setState(() {
        _player = p;
        _myTeamIds = myTeamIds;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    return result?.files.single.path;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _darkBg,
        body: Center(
          child: CircularProgressIndicator(color: _lime),
        ),
      );
    }

    if (_player == null) {
      return _buildErrorScaffold('Joueur introuvable');
    }

    if (_player!.role == UserRole.admin) {
      return _buildErrorScaffold(
        'Ce compte est réservé à l\'administration.\nL\'application joueur n\'est pas accessible avec ce profil.',
        title: 'Accès refusé',
      );
    }

    return Scaffold(
      backgroundColor: _darkBg,
      extendBody: true,
      body: Stack(
        children: [
          // Background decorative orbs
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _lime.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            top: 300,
            left: -60,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00A8FF).withValues(alpha: 0.04),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: switch (_selectedIndex) {
                0 => KeyedSubtree(key: const ValueKey(0), child: _buildHomeTab()),
                1 => KeyedSubtree(key: const ValueKey(1), child: MonEquipeScreen(userId: widget.userId)),
                _ => KeyedSubtree(key: const ValueKey(2), child: PlayerProfileScreen(currentUser: _player!)),
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildHomeTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        Expanded(
          child: MesMatchsScreen(userId: widget.userId, teamIds: _myTeamIds),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _lime.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: _lime.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with lime ring
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_lime, Color(0xFF00A8FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: CircleAvatar(
                  radius: 34,
                  backgroundColor: const Color(0xFF1A2535),
                  backgroundImage: _getAvatarImage(),
                  child: _getAvatarChild(),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () async {
                    final picked = await _pickPhoto();
                    if (picked == null) return;
                    final players = await _playersService.getAllPlayers();
                    final idx = players.indexWhere((p) => p.id == widget.userId);
                    if (idx != -1) {
                      final maps = players.map((p) => p.toJson()).toList();
                      maps[idx]['photoPath'] = picked;
                      await MockPersistence.saveList('mock.players', maps);
                      await _loadPlayer();
                    }
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _lime,
                      shape: BoxShape.circle,
                      border: Border.all(color: _cardBg, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, size: 12, color: Color(0xFF080C14)),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _player?.nom ?? 'Joueur',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _player?.email ?? '',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _StatBadge(
                      label: 'Niveau',
                      value: '${_player?.niveau ?? 1}',
                      color: _lime,
                    ),
                    const SizedBox(width: 8),
                    _StatBadge(
                      label: 'Joueur',
                      value: 'PRO',
                      color: const Color(0xFF00A8FF),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Logout
          GestureDetector(
            onTap: () async {
              await _authService.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.white54, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1520),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: NavigationBar(
        backgroundColor: Colors.transparent,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          _loadPlayer();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.shield_rounded),
            label: 'Mon Équipe',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScaffold(String message, {String title = 'Mon Espace Joueur'}) {
    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }

  ImageProvider? _getAvatarImage() {
    final path = _player?.photoPath;
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('data:')) {
      final base64Str = path.split(',').last;
      return MemoryImage(base64Decode(base64Str));
    }
    return NetworkImage(path);
  }

  Widget? _getAvatarChild() {
    final path = _player?.photoPath;
    if (path != null && path.isNotEmpty) return null;
    final initial = _player?.nom.isNotEmpty == true ? _player!.nom[0].toUpperCase() : '?';
    return Text(
      initial,
      style: const TextStyle(color: _lime, fontWeight: FontWeight.w800, fontSize: 22),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}