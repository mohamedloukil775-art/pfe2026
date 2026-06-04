import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../data/services/services.dart';
import '../auth/login_screen.dart';
import 'classement/classement_tab.dart';
import 'dashboard/dashboard_tab.dart';
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

  static const _lime    = Color(0xFFC8F000);
  static const _darkBg  = Color(0xFF080C14);
  static const _sideBar = Color(0xFF0D1520);
  static const _cardBg  = Color(0xFF0F1621);

  static const _navItems = [
    (Icons.grid_view_rounded,         Icons.grid_view_outlined,         'Tableau'),
    (Icons.people_alt_rounded,        Icons.people_alt_outlined,        'Joueurs'),
    (Icons.groups_rounded,            Icons.groups_outlined,            'Équipes'),
    (Icons.sports_tennis_rounded,     Icons.sports_tennis_outlined,     'Matchs'),
    (Icons.emoji_events_rounded,      Icons.emoji_events_outlined,      'Classement'),
    (Icons.workspace_premium_rounded, Icons.workspace_premium_outlined, 'Tournois'),
  ];

  final List<Widget> _tabs = const [
    DashboardTab(),
    JoueursTab(),
    EquipesTab(),
    MatchsTab(),
    ClassementTab(),
    TournoisTab(),
  ];

  Future<void> _logout() async {
    final navigator = Navigator.of(context);
    await _authService.logout();
    if (!mounted) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = kIsWeb || width >= 800;
    return isWide ? _buildWebLayout() : _buildMobileLayout();
  }

  // ── WEB / WIDE LAYOUT ─────────────────────────────────────────────────────

  Widget _buildWebLayout() {
    return Scaffold(
      backgroundColor: _darkBg,
      body: Row(
        children: [
          _buildSidebar(),
          Container(width: 1, color: Colors.white.withValues(alpha: 0.06)),
          Expanded(
            child: Column(
              children: [
                _buildWebTopBar(),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0F1419), Color(0xFF121A25), Color(0xFF0F1419)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: KeyedSubtree(
                        key: ValueKey(_currentIndex),
                        child: _tabs[_currentIndex],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 210,
      color: _sideBar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Logo / Header ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(18, 28, 18, 20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_lime, Color(0xFF8BC700)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.sports_tennis_rounded, color: Colors.black, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Padel Admin',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                      Text('Control Center',
                          style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 0.3)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // ── Navigation items ────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _navItems.length,
              itemBuilder: (_, i) {
                final (selIcon, unselIcon, label) = _navItems[i];
                final selected = _currentIndex == i;
                return InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() => _currentIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: selected ? _lime.withValues(alpha: 0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: selected
                          ? Border.all(color: _lime.withValues(alpha: 0.28))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(selected ? selIcon : unselIcon,
                            color: selected ? _lime : Colors.white54, size: 20),
                        const SizedBox(width: 10),
                        Text(label,
                            style: TextStyle(
                              color: selected ? _lime : Colors.white70,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                              fontSize: 14,
                            )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // ── Logout ─────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
            ),
            padding: const EdgeInsets.all(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: _logout,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.red.shade400, size: 18),
                    const SizedBox(width: 10),
                    Text('Déconnexion',
                        style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildWebTopBar() {
    const labels = ['Tableau de bord', 'Joueurs', 'Équipes', 'Matchs', 'Classement', 'Tournois'];
    const icons  = [
      Icons.grid_view_rounded,
      Icons.people_alt_rounded,
      Icons.groups_rounded,
      Icons.sports_tennis_rounded,
      Icons.emoji_events_rounded,
      Icons.workspace_premium_rounded,
    ];
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: _cardBg,
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: Row(
        children: [
          Icon(icons[_currentIndex], color: _lime, size: 20),
          const SizedBox(width: 10),
          Text(
            labels[_currentIndex],
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Padel Championship',
              style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ── MOBILE LAYOUT (unchanged) ──────────────────────────────────────────────

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 92,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A1F3A), Color(0xFF1E2340), Color(0xFF1A1F3A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(children: [
            Positioned(
              top: -26, right: -18,
              child: Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _lime.withValues(alpha: 0.15),
                ),
              ),
            ),
            Positioned(
              bottom: -20, left: 120,
              child: Container(
                width: 74, height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _lime.withValues(alpha: 0.10),
                ),
              ),
            ),
          ]),
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
              child: const Text('Padel Control Center',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            ),
            const SizedBox(height: 6),
            const Text('Administration Championnat'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: OutlinedButton.icon(
              onPressed: _logout,
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
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: KeyedSubtree(
            key: ValueKey(_currentIndex),
            child: _tabs[_currentIndex],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.grid_view_rounded),   label: 'Tableau'),
          NavigationDestination(icon: Icon(Icons.people),              label: 'Joueurs'),
          NavigationDestination(icon: Icon(Icons.groups),              label: 'Équipes'),
          NavigationDestination(icon: Icon(Icons.sports),              label: 'Matchs'),
          NavigationDestination(icon: Icon(Icons.emoji_events),        label: 'Classement'),
          NavigationDestination(icon: Icon(Icons.workspace_premium),   label: 'Tournois'),
        ],
      ),
    );
  }
}
