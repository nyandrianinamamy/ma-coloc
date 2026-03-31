import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:macoloc/src/features/home/home_screen.dart';

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

  group('Home feed', () {
    testWidgets('activity feed displays seeded events', (tester) async {
      final houseId = await setupUserWithHouse(
        tester,
        email: 'alice@test.com',
        displayName: 'Alice',
        houseName: 'Feed House',
      );

      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Seed activity events (normally written by Cloud Functions)
      await seedDocument('houses/$houseId/activity/badge1', {
        'type': 'badgeEarned',
        'uid': uid,
        'displayName': 'Alice',
        'detail': 'First Blood',
        'createdAt': Timestamp.now(),
      });

      await seedDocument('houses/$houseId/activity/streak1', {
        'type': 'streakMilestone',
        'uid': uid,
        'displayName': 'Alice',
        'detail': '7',
        'createdAt': Timestamp.now(),
      });

      // Seed an issue for the feed
      await FirebaseFirestore.instance
          .collection('houses/$houseId/issues')
          .add({
        'type': 'chore',
        'title': 'Take out trash',
        'createdBy': uid,
        'createdAt': Timestamp.now(),
        'status': 'open',
        'points': 50,
        'anonymous': false,
      });

      // Refresh home screen by navigating away and back
      await tapText(tester, 'Issues');
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tapText(tester, 'Home');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify activity items are displayed
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.textContaining('First Blood'), findsWidgets);
    });

    testWidgets('momentum card shows correct text for 0 resolved', (tester) async {
      await setupUserWithHouse(
        tester,
        email: 'alice@test.com',
        displayName: 'Alice',
        houseName: 'Momentum House',
      );

      // With 0 resolved issues, momentum text should indicate "get started"
      expect(find.textContaining('get started'), findsOneWidget);
    });

    testWidgets('volunteer nudge appears with unclaimed rooms', (tester) async {
      final houseId = await setupUserWithHouse(
        tester,
        email: 'alice@test.com',
        displayName: 'Alice',
        houseName: 'Nudge House',
      );

      // Seed a deep clean with unclaimed rooms
      final now = DateTime.now();
      await FirebaseFirestore.instance
          .collection('houses/$houseId/deepCleans')
          .add({
        'createdAt': Timestamp.fromDate(now),
        'deadline': Timestamp.fromDate(now.add(const Duration(days: 7))),
        'status': 'active',
        'rooms': {
          'Kitchen': {'claimedBy': null, 'completedAt': null, 'points': 100},
          'Bathroom': {'claimedBy': null, 'completedAt': null, 'points': 100},
        },
      });

      // Refresh home
      await tapText(tester, 'Issues');
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tapText(tester, 'Home');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should see volunteer nudge with "unclaimed"
      expect(find.textContaining('unclaimed'), findsOneWidget);
    });
  });
}
