import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/core/storage/token_storage.dart';

Future<void> _waitForFinder(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < timeout) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  fail('Timeout waiting for widget: $finder');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await TokenStorage.clearAll();
  });

  testWidgets('App shows login screen when no session exists', (tester) async {
    final startupStopwatch = Stopwatch()..start();

    await tester.pumpWidget(const PadelChampionshipApp());

    await _waitForFinder(tester, find.text('Email'));
    await _waitForFinder(tester, find.text('Se connecter'));

    startupStopwatch.stop();
    // Keep an objective threshold for startup readiness in CI/local runs.
    expect(startupStopwatch.elapsedMilliseconds, lessThan(3000));

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });
}
