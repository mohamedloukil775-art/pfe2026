import 'package:flutter/material.dart';
import '../../data/services/firestore_service.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/team.dart';

class AdminTeamManagementScreen extends StatefulWidget {
  const AdminTeamManagementScreen({super.key});

  @override
  State<AdminTeamManagementScreen> createState() =>
      _AdminTeamManagementScreenState();
}

class _AdminTeamManagementScreenState extends State<AdminTeamManagementScreen> {
  late FirestoreService _firestoreService;
  List<Team> _teams = [];
  List<AppUser> _players = [];
  Map<int, List<AppUser>> _teamPlayers = {};
  bool _isLoading = true;
  String? _selectedTeamId;
  String? _selectedPlayerEmail;

  @override
  void initState() {
    super.initState();
    _firestoreService = FirestoreService();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final teams = await _firestoreService.getAllTeams();
      final players = await _firestoreService.getAllUsers();

      // Filter to only joueurs (players)
      players.removeWhere((p) => p.nom.isEmpty);

      // Load team players
      final teamPlayers = <int, List<AppUser>>{};
      for (final team in teams) {
        final playersInTeam = await _firestoreService.getPlayersInTeam(team.id);
        teamPlayers[team.id] = playersInTeam;
      }

      setState(() {
        _teams = teams;
        _players = players;
        _teamPlayers = teamPlayers;
      });
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _assignPlayerToTeam() async {
    if (_selectedTeamId == null || _selectedPlayerEmail == null) {
      _showError('Veuillez sélectionner un joueur et une équipe');
      return;
    }

    final teamId = int.parse(_selectedTeamId!);
    final player = _players.firstWhere((p) => p.email == _selectedPlayerEmail);

    try {
      // Validate level compatibility
      final canJoin = await _firestoreService.canPlayerJoinTeam(
        playerLevel: player.niveau,
        teamId: teamId,
      );

      if (!canJoin) {
        _showError(
            'Le joueur n\'a pas le bon niveau pour rejoindre cette équipe');
        return;
      }

      // Assign player to team
      await _firestoreService.assignPlayerToTeam(
        playerEmail: _selectedPlayerEmail!,
        teamId: teamId,
      );

      _showSuccess('Joueur assigné à l\'équipe avec succès!');
      _selectedPlayerEmail = null;
      _selectedTeamId = null;
      await _loadData();
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _removePlayerFromTeam(String playerEmail) async {
    try {
      await _firestoreService.removePlayerFromTeam(playerEmail);
      _showSuccess('Joueur retiré de l\'équipe');
      await _loadData();
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF58D6B0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Équipes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Assign Player Section
            Text(
              'Assigner un Joueur',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF58D6B0),
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sélectionner un joueur:'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedPlayerEmail,
                      items: _players.map((player) {
                        return DropdownMenuItem(
                          value: player.email,
                          child: Text('${player.nom} (${player.email})'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedPlayerEmail = value);
                      },
                      decoration: InputDecoration(
                        hintText: 'Choisir un joueur',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Sélectionner une équipe:'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTeamId,
                      items: _teams.map((team) {
                        return DropdownMenuItem(
                          value: team.id.toString(),
                          child: Text('${team.nom} (Niveau ${team.niveau})'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedTeamId = value);
                      },
                      decoration: InputDecoration(
                        hintText: 'Choisir une équipe',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _assignPlayerToTeam,
                      child: const Text('Assigner'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Teams List
            Text(
              'Équipes et Joueurs',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF58D6B0),
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _teams.length,
              itemBuilder: (context, index) {
                final team = _teams[index];
                final playersInTeam = _teamPlayers[team.id] ?? [];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ExpansionTile(
                    title: Text(
                      '${team.nom} (Niveau ${team.niveau})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF58D6B0),
                      ),
                    ),
                    subtitle: Text(
                      '${playersInTeam.length} joueur(s)',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    children: [
                      if (playersInTeam.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Aucun joueur assigné',
                            style: TextStyle(
                              color: Colors.white54,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: playersInTeam.length,
                          itemBuilder: (context, playerIndex) {
                            final player = playersInTeam[playerIndex];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF58D6B0),
                                child: Text(
                                  player.nom[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(player.nom),
                              subtitle: Text(
                                '${player.email} • Niveau ${player.niveau}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Confirmation'),
                                      content: Text(
                                        'Retirer ${player.nom} de l\'équipe?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Annuler'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Retirer'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirmed == true) {
                                    await _removePlayerFromTeam(player.email);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
