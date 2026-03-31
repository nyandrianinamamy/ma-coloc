import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'e2e_helpers.dart';
import 'issue_lifecycle_test.dart' show setupUserWithHouse;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initFirebaseForTest();
  });

  setUp(() async {
    await resetEmulators();
  });

  group('Settings flow', () {
    testWidgets('admin updates house name via callable', (tester) async {
      final houseId = await setupUserWithHouse(
        tester,
        email: 'alice@test.com',
        displayName: 'Alice',
        houseName: 'Old Name',
      );

      // Update house name via callable
      final functions = FirebaseFunctions.instance;
      await functions.httpsCallable('updateHouse').call({
        'houseId': houseId,
        'name': 'New Name',
      });

      // Verify Firestore
      final houseDoc = await FirebaseFirestore.instance.doc('houses/$houseId').get();
      expect(houseDoc.data()!['name'], 'New Name');
    });

    testWidgets('admin promotes member and removes member', (tester) async {
      // Create user 1 (admin) with house
      final cred1 = await createTestUser('alice@test.com', 'password123');
      await pumpApp(tester);

      await tapText(tester, 'Create a House');
      await enterTextField(tester, 'Your Display Name', 'Alice');
      await enterTextField(tester, 'House Name', 'Admin House');
      await tapTextAndWait(tester, 'Create House', timeout: const Duration(seconds: 10));

      final uid1 = cred1.user!.uid;
      final housesSnap = await FirebaseFirestore.instance
          .collection('houses')
          .where('members', arrayContains: uid1)
          .get();
      final houseId = housesSnap.docs.first.id;
      final inviteCode = housesSnap.docs.first.data()['inviteCode'] as String;

      // Sign out user 1
      await signOutTestUser();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Create user 2 and join house
      final cred2 = await createTestUser('bob@test.com', 'password123');
      await pumpApp(tester);
      await tapText(tester, 'Join with Invite Code');
      await enterTextField(tester, 'Invite Code', inviteCode);
      await enterTextField(tester, 'Your Display Name', 'Bob');
      await tapTextAndWait(tester, 'Join House', timeout: const Duration(seconds: 10));

      final uid2 = cred2.user!.uid;

      // Sign out user 2, sign in user 1 (admin)
      await signOutTestUser();
      await signInTestUser('alice@test.com', 'password123');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Promote user 2 via callable
      final functions = FirebaseFunctions.instance;
      await functions.httpsCallable('updateMemberRole').call({
        'houseId': houseId,
        'targetUid': uid2,
        'newRole': 'admin',
      });

      // Verify promotion
      final memberDoc = await FirebaseFirestore.instance
          .doc('houses/$houseId/members/$uid2')
          .get();
      expect(memberDoc.data()!['role'], 'admin');

      // Remove user 2 via callable
      await functions.httpsCallable('removeMember').call({
        'houseId': houseId,
        'targetUid': uid2,
      });

      // Verify removal
      final memberDoc2 = await FirebaseFirestore.instance
          .doc('houses/$houseId/members/$uid2')
          .get();
      expect(memberDoc2.exists, false);
    });

    testWidgets('leave house removes member from Firestore', (tester) async {
      final houseId = await setupUserWithHouse(
        tester,
        email: 'alice@test.com',
        displayName: 'Alice',
        houseName: 'Temp House',
      );

      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Leave house via callable
      final functions = FirebaseFunctions.instance;
      await functions.httpsCallable('leaveHouse').call({
        'houseId': houseId,
      });

      // Verify no longer a member
      final memberDoc = await FirebaseFirestore.instance
          .doc('houses/$houseId/members/$uid')
          .get();
      expect(memberDoc.exists, false);
    });
  });
}
