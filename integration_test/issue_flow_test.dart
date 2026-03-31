import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macoloc/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Issue lifecycle E2E', () {
    testWidgets('app boots without crashing', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaColocApp()),
      );
      // Give the app time to initialize (Firebase, router redirect, etc.)
      await tester.pump(const Duration(seconds: 3));

      // The app should render something — either home (placeholder mode)
      // or sign-in (real Firebase without auth). Just verify no crash.
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
