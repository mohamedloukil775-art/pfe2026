// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

import 'package:flutter_application_1/main.dart';

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

  setUp(() {
    store.clear();
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('Login screen is displayed', (WidgetTester tester) async {
    await tester.pumpWidget(const PadelChampionshipApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Championnat Padel'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });

  testWidgets('Auto login routes to admin when admin session exists',
      (WidgetTester tester) async {
    store['user_id'] = '1';
    store['user_name'] = 'Admin Club';
    store['user_role'] = 'Admin';

    await tester.pumpWidget(const PadelChampionshipApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Administration Championnat'), findsOneWidget);
  });

  testWidgets('Auto login routes to player when player session exists',
      (WidgetTester tester) async {
    store['user_id'] = '2';
    store['user_name'] = 'Ali Ben';
    store['user_role'] = 'Joueur';

    await tester.pumpWidget(const PadelChampionshipApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Mon Espace Joueur'), findsOneWidget);
  });
}
