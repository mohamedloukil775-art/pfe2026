import 'package:flutter/material.dart';
import '../../domain/models/app_user.dart';
import '../../domain/enums/user_role.dart';
import '../../data/services/firebase_auth_service.dart';
import '../admin/admin_home_screen.dart';
import '../player/player_home_screen.dart';
import '../player/player_profile_screen.dart';
import '../player/mes_matchs_screen.dart';

class RoleBasedNavigation extends StatefulWidget {
  final AppUser currentUser;

  const RoleBasedNavigation({
    super.key,
    required this.currentUser,
  });

  @override
  State<RoleBasedNavigation> createState() => _RoleBasedNavigationState();
}

class _RoleBasedNavigationState extends State<RoleBasedNavigation> {
  late FirebaseAuthService _authService;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _authService = FirebaseAuthService();
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _authService.logout();
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  // Admin Navigation
  Widget _buildAdminView() {
    return const AdminHomeScreen();
  }

  // Player Navigation with BottomNavigationBar
  Widget _buildPlayerView() {
    final screens = [
      PlayerHomeScreen(userId: widget.currentUser.id),
      MesMatchsScreen(userId: widget.currentUser.id),
      PlayerProfileScreen(currentUser: widget.currentUser),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_soccer),
            label: 'Matchs',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentUser.role == UserRole.admin) {
      return _buildAdminView();
    } else {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (!didPop) await _logout();
        },
        child: _buildPlayerView(),
      );
    }
  }
}
