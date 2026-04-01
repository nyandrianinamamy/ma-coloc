import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:macoloc/src/features/home/home_screen.dart';
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

  group('Onboarding: Create house', () {
    testWidgets('createHouse callable creates house and member', (tester) async {
      final cred = await createTestUser('alice@test.com', 'password123');
      await pumpApp(tester);

      // Should be on onboarding (no house)
      expect(find.byType(HouseChoiceScreen), findsOneWidget);

      // Create house programmatically (UI tap has web-specific timing issues)
      final functions = FirebaseFunctions.instance;
      final result = await functions.httpsCallable('createHouse').call({
        'name': 'Test Apartment',
        'displayName': 'Alice',
        'timezone': 'Europe/Paris',
        'rooms': ['Kitchen', 'Bathroom'],
      });
      final houseId = result.data['houseId'] as String;

      // Verify Firestore: house document exists
      final houseDoc = await FirebaseFirestore.instance.doc('houses/$houseId').get();
      expect(houseDoc.exists, true);
      expect(houseDoc.data()!['name'], 'Test Apartment');
      expect(houseDoc.data()!['inviteCode'], isNotEmpty);
      expect((houseDoc.data()!['members'] as List).contains(cred.user!.uid), true);

      // Verify member doc exists
      final memberDoc = await FirebaseFirestore.instance
          .doc('houses/$houseId/members/${cred.user!.uid}')
          .get();
      expect(memberDoc.exists, true);
      expect(memberDoc.data()!['displayName'], 'Alice');
      expect(memberDoc.data()!['role'], 'admin');

      // Re-pump app — should now route to home
      await pumpApp(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('Onboarding: Join house', () {
    testWidgets('joinHouse callable adds second member', (tester) async {
      // User 1 creates house
      final cred1 = await createTestUser('alice@test.com', 'password123');
      final functions = FirebaseFunctions.instance;
      final createResult = await functions.httpsCallable('createHouse').call({
        'name': 'Shared Flat',
        'displayName': 'Alice',
        'timezone': 'Europe/Paris',
        'rooms': ['Kitchen'],
      });
      final houseId = createResult.data['houseId'] as String;

      // Get invite code
      final houseDoc = await FirebaseFirestore.instance.doc('houses/$houseId').get();
      final inviteCode = houseDoc.data()!['inviteCode'] as String;

      // Sign out user 1, create user 2
      await signOutTestUser();
      final cred2 = await createTestUser('bob@test.com', 'password123');

      // User 2 joins house
      final joinResult = await functions.httpsCallable('joinHouse').call({
        'inviteCode': inviteCode,
        'displayName': 'Bob',
      });
      expect(joinResult.data['houseId'], houseId);

      // Verify both members exist
      final membersSnap = await FirebaseFirestore.instance
          .collection('houses/$houseId/members')
          .get();
      expect(membersSnap.docs.length, 2);

      final memberUids = membersSnap.docs.map((d) => d.id).toSet();
      expect(memberUids.contains(cred1.user!.uid), true);
      expect(memberUids.contains(cred2.user!.uid), true);

      // Pump app for user 2 — should go to home (has house)
      await pumpApp(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
