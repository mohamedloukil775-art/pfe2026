import 'package:flutter/material.dart';

import '../../../data/services/services.dart';
import '../../../domain/domain.dart';

class ClassementTab extends StatefulWidget {
  const ClassementTab({super.key});

  @override
  State<ClassementTab> createState() => _ClassementTabState();
}

class _ClassementTabState extends State<ClassementTab> {
  static const _lime = Color(0xFFC8F000);
  static const _cardBg = Color(0xFF0F1621);
  final StandingsServiceMock _standingsService = StandingsServiceMock();
  final ClubsServiceMock _clubsService = ClubsServiceMock();

  List<PlayerStanding> _standings = const [];
  List<ClubStanding> _clubRankings = const [];
  List<Reward> _top3 = const [];
  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _error;
  String _searchQuery = '';

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
        _standingsService.getStandings(),
        _clubsService.getClubRankings(),
      ]);

      final standings = results[0] as List<PlayerStanding>;
      final clubRankings = results[1] as List<ClubStanding>;

      if (!mounted) return;
      setState(() {
        _standings = standings;
        _clubRankings = clubRankings;
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

  Future<void> _generateTop3() async {
    setState(() => _isActionLoading = true);
    try {
      final rewards = await _standingsService.getMonthlyTop3();
      if (!mounted) return;
      setState(() {
        _top3 = rewards;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Top 3 mensuel généré.')),
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

  List<PlayerStanding> get _filteredStandings {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _standings;
    return _standings.where((player) {
      return player.nom.toLowerCase().contains(query) ||
          player.points.toString().contains(query) ||
          player.niveau.toString().contains(query) ||
          player.victoires.toString().contains(query);
    }).toList();
  }

  List<ClubStanding> get _filteredClubRankings {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _clubRankings;
    return _clubRankings.where((club) {
      return club.nom.toLowerCase().contains(query) ||
          club.localisation.toLowerCase().contains(query) ||
          club.pointsTotal.toString().contains(query) ||
          club.nombreJoueurs.toString().contains(query);
    }).toList();
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required IconData icon,
    required List<Color> colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
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

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
        ),
      ],
    );
  }

  String _rewardLabel(int position) {
    switch (position) {
      case 1:
        return 'Trophee Or';
      case 2:
        return 'Trophee Argent';
      case 3:
        return 'Trophee Bronze';
      default:
        return 'Top $position';
    }
  }

  Color _rewardColor(int position) {
    switch (position) {
      case 1:
        return Colors.amber.shade700;
      case 2:
        return Colors.grey.shade500;
      case 3:
        return Colors.brown.shade400;
      default:
        return Colors.blueGrey;
    }
  }

  String _playerNameById(int id) {
    for (final player in _standings) {
      if (player.joueurId == id) return player.nom;
    }
    return 'Joueur #$id';
  }

  Widget _buildTop3Section() {
    if (_top3.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Aucun Top 3 généré pour le moment. Cliquez sur "Générer Top 3".',
          textAlign: TextAlign.center,
        ),
      );
    }

    final ordered = [..._top3]..sort((a, b) => a.position.compareTo(b.position));

    return Column(
      children: ordered
          .map(
            (reward) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _rewardColor(reward.position),
                  child: Text(
                    reward.position.toString(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(_playerNameById(reward.joueurId)),
                subtitle: Text(_rewardLabel(reward.position)),
              ),
            ),
          )
          .toList(),
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
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ),
          ],
        ),
      );
    }

    final filteredStandings = _filteredStandings;
    final filteredClubs = _filteredClubRankings;
    final bestPlayerPoints = _standings.isEmpty ? 0 : _standings.first.points;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _lime.withValues(alpha: 0.10)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Classement',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Suivi des joueurs, clubs et récompenses mensuelles.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isActionLoading ? null : _generateTop3,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _lime,
                        foregroundColor: const Color(0xFF080C14),
                      ),
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Générer Top 3'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Rechercher un joueur, un club, une ville...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2.2,
                  children: [
                    _buildSummaryCard(
                      label: 'Joueurs classés',
                      value: _standings.length.toString(),
                      icon: Icons.emoji_events_outlined,
                      colors: [_lime.withValues(alpha: 0.85), _lime],
                    ),
                    _buildSummaryCard(
                      label: 'Clubs suivis',
                      value: _clubRankings.length.toString(),
                      icon: Icons.groups_2_outlined,
                      colors: [const Color(0xFF14B8A6), const Color(0xFF0F766E)],
                    ),
                    _buildSummaryCard(
                      label: 'Top joueur',
                      value: bestPlayerPoints.toString(),
                      icon: Icons.star_outline,
                      colors: [const Color(0xFFF59E0B), const Color(0xFFB45309)],
                    ),
                    _buildSummaryCard(
                      label: 'Top 3 prêts',
                      value: _top3.length.toString(),
                      icon: Icons.workspace_premium_outlined,
                      colors: [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _buildSectionHeader(
            'Classement joueurs',
            'Résultats filtrés selon la recherche active.',
          ),
          const SizedBox(height: 10),
          Card(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Pos')),
                  DataColumn(label: Text('Nom')),
                  DataColumn(label: Text('Niveau')),
                  DataColumn(label: Text('Pts')),
                  DataColumn(label: Text('V')),
                  DataColumn(label: Text('D')),
                  DataColumn(label: Text('Diff')),
                ],
                rows: filteredStandings.isEmpty
                    ? []
                    : List<DataRow>.generate(
                        filteredStandings.length,
                        (index) {
                          final player = filteredStandings[index];
                          return DataRow(
                            cells: [
                              DataCell(Text((index + 1).toString())),
                              DataCell(Text(player.nom)),
                              DataCell(Text(player.niveau.toString())),
                              DataCell(Text(player.points.toString())),
                              DataCell(Text(player.victoires.toString())),
                              DataCell(Text(player.defaites.toString())),
                              DataCell(Text(player.differenceSet.toString())),
                            ],
                          );
                        },
                      ),
              ),
            ),
          ),
          if (filteredStandings.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text('Aucun joueur ne correspond à la recherche.'),
            ),
          const SizedBox(height: 20),
          _buildSectionHeader(
            'Classement clubs',
            'Vue consolidée des clubs et de leurs performances.',
          ),
          const SizedBox(height: 10),
          Card(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Pos')),
                  DataColumn(label: Text('Club')),
                  DataColumn(label: Text('Ville')),
                  DataColumn(label: Text('Joueurs')),
                  DataColumn(label: Text('Niv. moyen')),
                  DataColumn(label: Text('Pts total')),
                ],
                rows: filteredClubs
                    .map(
                      (club) => DataRow(
                        cells: [
                          DataCell(Text(club.position.toString())),
                          DataCell(Text(club.nom)),
                          DataCell(Text(club.localisation)),
                          DataCell(Text(club.nombreJoueurs.toString())),
                          DataCell(Text(club.niveauMoyen.toStringAsFixed(2))),
                          DataCell(Text(club.pointsTotal.toString())),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          if (filteredClubs.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text('Aucun club ne correspond à la recherche.'),
            ),
          const SizedBox(height: 20),
          _buildSectionHeader(
            'Top 3 mensuel',
            'Récompenses générées automatiquement à partir du classement.' ,
          ),
          const SizedBox(height: 10),
          _buildTop3Section(),
        ],
      ),
    );
  }
}
