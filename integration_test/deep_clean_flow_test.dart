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

  group('Deep clean flow', () {
    testWidgets('claim room and complete via callable', (tester) async {
      final houseId = await setupUserWithHouse(
        tester,
        email: 'alice@test.com',
        displayName: 'Alice',
        houseName: 'Clean House',
      );

      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Seed a deep clean cycle using the correct schema (assignments, not rooms)
      final now = DateTime.now();
      final deadline = now.add(const Duration(days: 7));
      final deepCleanRef = FirebaseFirestore.instance
          .collection('houses/$houseId/deepCleans')
          .doc();
      await deepCleanRef.set({
        'createdAt': Timestamp.fromDate(now),
        'deadline': Timestamp.fromDate(deadline),
        'status': 'active',
        'assignments': {
          'Kitchen': {'uid': null, 'fromVolunteer': false, 'completed': false},
          'Bathroom': {'uid': null, 'fromVolunteer': false, 'completed': false},
        },
      });

      // Claim Kitchen via callable (uses cleanId, not deepCleanId)
      final functions = FirebaseFunctions.instance;
      await functions.httpsCallable('claimRoom').call({
        'houseId': houseId,
        'cleanId': deepCleanRef.id,
        'roomName': 'Kitchen',
      });

      // Verify room is claimed
      final dcDoc = await deepCleanRef.get();
      final assignments = dcDoc.data()!['assignments'] as Map<String, dynamic>;
      final kitchen = assignments['Kitchen'] as Map<String, dynamic>;
      expect(kitchen['uid'], uid);

      // Complete the room via callable
      await functions.httpsCallable('completeRoom').call({
        'houseId': houseId,
        'cleanId': deepCleanRef.id,
        'roomName': 'Kitchen',
      });

      // Verify room is completed
      final dcDoc2 = await deepCleanRef.get();
      final assignments2 = dcDoc2.data()!['assignments'] as Map<String, dynamic>;
      final kitchen2 = assignments2['Kitchen'] as Map<String, dynamic>;
      expect(kitchen2['completedAt'], isNotNull);

      // Verify activity doc was written
      final activitySnap = await FirebaseFirestore.instance
          .collection('houses/$houseId/activity')
          .get();
      expect(activitySnap, isNotNull);
    });
  });
}
