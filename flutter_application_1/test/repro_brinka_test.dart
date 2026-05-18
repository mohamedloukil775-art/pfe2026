import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:flutter_application_1/data/services/services.dart';
import 'package:flutter_application_1/domain/domain.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Reproduce Brinka scenario', () async {
    // Provide mock initial values for shared_preferences used by MockPersistence
    // so plugin calls don't throw in unit tests.
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final playersService = PlayersServiceMock();
    final authService = AuthServiceMock();
    final teamsService = TeamsServiceMock();

    final String nom = 'Brinka';
    final String email = 'brinka@padel.com';
    final String password = 'Brinka123!';

    // Create Brinka
    AppUser created = await playersService.createPlayer(
      nom: nom,
      email: email,
      password: password,
      niveau: 4,
      photoPath: null,
      clubId: 1,
    );

    print('Created player id=${created.id} email=${created.email} nom=${created.nom}');

    // Attempt duplicate creation (should throw)
    Object? duplicateError;
    try {
      await playersService.createPlayer(
        nom: nom,
        email: email,
        password: password,
        niveau: 4,
        photoPath: null,
        clubId: 1,
      );
    } catch (e) {
      duplicateError = e;
      print('Duplicate creation error: $e');
    }

    // Login as Brinka
    final logged = await authService.login(email, password);
    print('Login returned id=${logged.id} email=${logged.email} nom=${logged.nom}');

    // Verify only one player with that email
    final all = await playersService.getAllPlayers();
    final matches = all.where((p) => p.email.toLowerCase() == email.toLowerCase()).toList();
    print('Players with email $email: ${matches.length}');

    // Check teams for membership
    final teams = await teamsService.getAllTeams();
    final inTeam = teams.any((t) => t.playerIds.contains(created.id));
    print('Is Brinka in any team? $inTeam');

    // Assertions
    expect(matches.length, 1);
    expect(duplicateError, isNotNull);
    expect(logged.email.toLowerCase(), email.toLowerCase());
    expect(inTeam, false);
  }, timeout: Timeout(Duration(seconds: 10)));
}
