import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:macoloc/src/features/home/home_screen.dart';
import 'package:macoloc/src/features/onboarding/welcome_screen.dart';

import 'e2e_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initFirebaseForTest();
  });

  setUp(() async {
    await resetEmulators();
  });

  group('Demo flow', () {
    testWidgets('explore with demo data then exit returns to welcome', (tester) async {
      await pumpApp(tester);

      // Should start on welcome screen (unauthenticated)
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.text('Explore with demo data'), findsOneWidget);

      // Tap "Explore with demo data" — triggers anonymous auth + seedDemoHouse callable
      await tapTextAndWait(tester, 'Explore with demo data',
          timeout: const Duration(seconds: 30));

      // Wait for navigation to home screen (auth + Firestore + router redirect)
      await waitForAsync(tester, find.byType(HomeScreen),
          timeout: const Duration(seconds: 30));

      // Verify demo house name is visible
      expect(find.textContaining('Appart Rue Exemple'), findsOneWidget);

      // Navigate to Profile tab (settings icon lives there)
      await tapText(tester, 'Profile');
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Tap the settings icon on the profile screen
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // On settings screen — tap "Exit Demo"
      await tapText(tester, 'Exit Demo');
      await tester.pumpAndSettle();

      // Confirm the dialog
      // The dialog has two buttons: "Cancel" and "Exit Demo" — tap "Exit Demo"
      final exitButtons = find.text('Exit Demo');
      // The last one is inside the dialog actions
      await tester.tap(exitButtons.last);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Wait for cleanup + sign-out → router should redirect to welcome
      await waitForAsync(tester, find.byType(WelcomeScreen),
          timeout: const Duration(seconds: 30));

      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.text('Explore with demo data'), findsOneWidget);
    });
  });
}
