import 'package:flutter/material.dart';

import '../../data/services/services.dart';
import '../auth/login_screen.dart';
import 'classement/classement_tab.dart';
import 'equipes/equipes_tab.dart';
import 'joueurs/joueurs_tab.dart';
import 'matchs/matchs_tab.dart';
import 'tournois/tournois_tab.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _authService = AuthService();
  int _currentIndex = 0;
  static const _lime = Color(0xFFC8F000);
  static const _headerGradient = LinearGradient(
    colors: [Color(0xFF1A1F3A), Color(0xFF1E2340), Color(0xFF1A1F3A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final List<Widget> _tabs = [
    const JoueursTab(),
    const EquipesTab(),
    const MatchsTab(),
    const ClassementTab(),
    const TournoisTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 92,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: _headerGradient),
          child: Stack(
            children: [
              Positioned(
                top: -26,
                right: -18,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _lime.withValues(alpha: 0.15),
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                left: 120,
                child: Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _lime.withValues(alpha: 0.10),
                  ),
                ),
              ),
            ],
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: const Text(
                'Padel Control Center',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text('Administration Championnat'),
            Text(
              'Gestion moderne des joueurs, equipes, matchs, classement et tournois',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: OutlinedButton.icon(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await _authService.logout();
              if (!mounted) return;
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
              icon: const Icon(Icons.logout),
              label: const Text('Déconnexion'),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F1419), Color(0xFF121A25), Color(0xFF0F1419)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -70,
              right: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _lime.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -50,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _lime.withValues(alpha: 0.06),
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: KeyedSubtree(
                key: ValueKey(_currentIndex),
                child: _tabs[_currentIndex],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people),
            label: 'Joueurs',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups),
            label: 'Équipes',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports),
            label: 'Matchs',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events),
            label: 'Classement',
          ),
          NavigationDestination(
            icon: Icon(Icons.workspace_premium),
            label: 'Tournois',
          ),
        ],
      ),
    );
  }
}
