import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/core/storage/token_storage.dart';
import 'package:flutter_application_1/data/services/auth_service_mock.dart';
import 'package:flutter_application_1/data/services/players_service_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final store = <String, String>{};

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'read':
          final key = call.arguments['key'] as String;
          return store[key];
        case 'write':
          final key = call.arguments['key'] as String;
          final value = call.arguments['value'] as String?;
          if (value != null) {
            store[key] = value;
          }
          return null;
        case 'deleteAll':
          store.clear();
          return null;
      }
      return null;
    });
  });

  setUp(() async {
    store.clear();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await TokenStorage.clearAll();
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('admin-created player can log in after persistence reload', () async {
    final playersService = PlayersServiceMock();
    final created = await playersService.createPlayer(
      nom: 'Test Joueur',
      email: 'test@padel.com',
      password: 'Player@123',
      niveau: 4,
      clubId: 1,
    );

    expect(created.email, 'test@padel.com');

    final reloadedPlayers = await PlayersServiceMock().getAllPlayers();
    expect(
      reloadedPlayers.any((player) => player.email == 'test@padel.com'),
      isTrue,
    );

    await TokenStorage.clearAll();

    final loggedIn = await AuthServiceMock().login(
      'test@padel.com',
      'Player@123',
    );

    expect(loggedIn.email, 'test@padel.com');
    expect(loggedIn.nom, 'Test Joueur');
  });
}