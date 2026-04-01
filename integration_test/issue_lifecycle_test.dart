import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:macoloc/src/features/home/home_screen.dart';

import 'e2e_helpers.dart';

/// Helper: create a user, create a house programmatically, and pump the app.
/// Returns the houseId.
Future<String> setupUserWithHouse(WidgetTester tester, {
  required String email,
  required String displayName,
  required String houseName,
}) async {
  await createTestUser(email, 'password123');

  // Create house programmatically via callable (more reliable than UI in web E2E)
  final functions = FirebaseFunctions.instance;
  final result = await functions.httpsCallable('createHouse').call({
    'name': houseName,
    'displayName': displayName,
    'timezone': 'Europe/Paris',
    'rooms': ['Kitchen', 'Bathroom'],
  });
  final houseId = result.data['houseId'] as String;

  // Pump the app — should land on home (user has a house now)
  await pumpApp(tester);
  await waitFor(tester, find.byType(HomeScreen), timeout: const Duration(seconds: 15));

  return houseId;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initFirebaseForTest();
  });

  setUp(() async {
    await resetEmulators();
  });

  group('Issue lifecycle', () {
    testWidgets('create issue, claim, and resolve end-to-end', (tester) async {
      final houseId = await setupUserWithHouse(
        tester,
        email: 'alice@test.com',
        displayName: 'Alice',
        houseName: 'Test House',
      );

      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Seed an issue directly in Firestore (camera won't work in headless Chrome)
      await FirebaseFirestore.instance
          .collection('houses/$houseId/issues')
          .add({
        'type': 'chore',
        'title': 'Dirty dishes in sink',
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'open',
        'points': 50,
        'anonymous': false,
      });

      // Navigate to issues tab
      await tapText(tester, 'Issues');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should see the issue in the list
      expect(find.text('Dirty dishes in sink'), findsOneWidget);

      // Tap the issue to view detail
      await tapText(tester, 'Dirty dishes in sink');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should see issue detail with "Claim Issue" button (status: open)
      expect(find.textContaining('Claim Issue'), findsOneWidget);

      // Claim the issue
      await tapTextAndWait(tester, 'Claim Issue (+50 pts)');

      // Now should see "Mark Resolved"
      expect(find.textContaining('Mark Resolved'), findsOneWidget);

      // Resolve the issue
      await tester.tap(find.text('Mark Resolved'));
      await tester.pumpAndSettle();

      // Resolution modal — confirm
      await tapTextAndWait(tester, 'Confirm Resolution');

      // Verify in Firestore: issue status is resolved
      final issuesSnap = await FirebaseFirestore.instance
          .collection('houses/$houseId/issues')
          .get();
      final issue = issuesSnap.docs.first.data();
      expect(issue['status'], 'resolved');
      expect(issue['resolvedBy'], uid);
    });
  });
}
