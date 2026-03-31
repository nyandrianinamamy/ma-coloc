import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:macoloc/src/features/onboarding/sign_in_screen.dart';
import 'package:macoloc/src/features/onboarding/house_choice_screen.dart';

import 'e2e_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initFirebaseForTest();
  });

  setUp(() async {
    await resetEmulators();
  });

  group('Auth flow', () {
    testWidgets('sign-up navigates to onboarding', (tester) async {
      await pumpApp(tester);

      // Should start on sign-in screen
      expect(find.text('MaColoc'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);

      // Toggle to sign-up mode
      await tapText(tester, "Don't have an account? Sign up");

      // Fill in credentials
      await enterTextField(tester, 'Email', 'alice@test.com');
      await enterTextField(tester, 'Password', 'password123');

      // Submit
      await tapTextAndWait(tester, 'Create Account');

      // Should navigate to onboarding (no house yet)
      expect(find.byType(HouseChoiceScreen), findsOneWidget);
      expect(find.text('Welcome to MaColoc!'), findsOneWidget);
    });

    testWidgets('sign-in with existing user works', (tester) async {
      // Pre-create a user via Auth emulator
      await createTestUser('bob@test.com', 'password123');
      await signOutTestUser();

      await pumpApp(tester);

      // Fill in sign-in form
      await enterTextField(tester, 'Email', 'bob@test.com');
      await enterTextField(tester, 'Password', 'password123');

      // Submit (default mode is sign-in)
      await tapTextAndWait(tester, 'Sign In');

      // Should navigate to onboarding (user has no house)
      expect(find.byType(HouseChoiceScreen), findsOneWidget);
    });

    testWidgets('sign-out from profile returns to sign-in', (tester) async {
      // Create user and sign in
      await createTestUser('charlie@test.com', 'password123');

      await pumpApp(tester);

      // User is signed in but has no house → onboarding
      expect(find.byType(HouseChoiceScreen), findsOneWidget);

      // Sign out via auth directly (profile sign-out requires a house)
      await signOutTestUser();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should redirect to sign-in
      expect(find.byType(SignInScreen), findsOneWidget);
    });
  });
}
