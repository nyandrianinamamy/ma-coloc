// Single entry point for all E2E tests.
// Flutter web integration tests require running all tests in one file
// because each flutter drive invocation starts a new browser session.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:macoloc/src/features/onboarding/welcome_screen.dart';
import 'package:macoloc/src/features/onboarding/house_choice_screen.dart';
import 'package:macoloc/src/features/home/home_screen.dart';

import 'e2e_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FirebaseFirestore firestore;
  late FirebaseAuth auth;
  late FirebaseFunctions functions;

  setUpAll(() async {
    final emulators = await connectEmulators();
    firestore = emulators.firestore;
    auth = emulators.auth;
    functions = emulators.functions;
  });

  setUp(() async {
    await resetEmulators();
  });

  // ── Auth Flow ──────────────────────────────────────────────────

  group('Auth', () {
    testWidgets('unauthenticated user sees welcome screen', (tester) async {
      await pumpApp(tester, firestore: firestore, auth: auth, functions: functions);
      expect(find.byType(WelcomeScreen), findsOneWidget);
    });

    testWidgets('sign-up navigates to onboarding', (tester) async {
      await pumpApp(tester, firestore: firestore, auth: auth, functions: functions);

      // Go to sign-in screen
      await tapText(tester, 'Log In with Email');
      await tester.pumpAndSettle();

      await tapText(tester, "Don't have an account? Sign up");
      await enterTextField(tester, 'Email', 'alice@test.com');
      await enterTextField(tester, 'Password', 'password123');

      await tester.tap(find.text('Create Account'));
      await waitFor(tester, find.byType(HouseChoiceScreen), timeout: const Duration(seconds: 30));
    });

    testWidgets('sign-in with existing user', (tester) async {
      await createTestUser('bob@test.com', 'password123');
      await signOutTestUser();

      await pumpApp(tester, firestore: firestore, auth: auth, functions: functions);

      await tapText(tester, 'Log In with Email');
      await tester.pumpAndSettle();

      await enterTextField(tester, 'Email', 'bob@test.com');
      await enterTextField(tester, 'Password', 'password123');

      await tester.tap(find.text('Sign In'));
      await waitFor(tester, find.byType(HouseChoiceScreen), timeout: const Duration(seconds: 30));
    });
  });

  // ── Onboarding: House Creation & Joining ───────────────────────

  group('Onboarding', () {
    testWidgets('createHouse callable creates house + member', (tester) async {
      final cred = await createTestUser('alice@test.com', 'password123');

      final result = await functions.httpsCallable('createHouse').call({
        'name': 'Test Apt',
        'displayName': 'Alice',
        'timezone': 'Europe/Paris',
        'rooms': ['Kitchen'],
      });
      final houseId = result.data['houseId'] as String;

      final houseDoc = await firestore.doc('houses/$houseId').get();
      expect(houseDoc.data()!['name'], 'Test Apt');
      expect(houseDoc.data()!['inviteCode'], isNotEmpty);

      final memberDoc = await firestore
          .doc('houses/$houseId/members/${cred.user!.uid}')
          .get();
      expect(memberDoc.data()!['role'], 'admin');

      await pumpApp(tester, firestore: firestore, auth: auth, functions: functions);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('joinHouse callable adds second member', (tester) async {
      await createTestUser('alice@test.com', 'password123');

      final createResult = await functions.httpsCallable('createHouse').call({
        'name': 'Shared Flat',
        'displayName': 'Alice',
        'timezone': 'Europe/Paris',
        'rooms': ['Kitchen'],
      });
      final houseId = createResult.data['houseId'] as String;

      final houseDoc = await firestore.doc('houses/$houseId').get();
      final inviteCode = houseDoc.data()!['inviteCode'] as String;

      await signOutTestUser();
      await createTestUser('bob@test.com', 'password123');

      await functions.httpsCallable('joinHouse').call({
        'inviteCode': inviteCode,
        'displayName': 'Bob',
      });

      final membersSnap = await firestore
          .collection('houses/$houseId/members')
          .get();
      expect(membersSnap.docs.length, 2);

      await pumpApp(tester, firestore: firestore, auth: auth, functions: functions);
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  // ── Issue Lifecycle ────────────────────────────────────────────

  group('Issues', () {
    testWidgets('seed issue, navigate, claim, resolve', (tester) async {
      await createTestUser('alice@test.com', 'password123');
      final result = await functions.httpsCallable('createHouse').call({
        'name': 'Issue House',
        'displayName': 'Alice',
        'timezone': 'Europe/Paris',
        'rooms': ['Kitchen'],
      });
      final houseId = result.data['houseId'] as String;
      final uid = auth.currentUser!.uid;

      await firestore.collection('houses/$houseId/issues').add({
        'type': 'chore',
        'title': 'Dirty dishes',
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'open',
        'points': 50,
        'anonymous': false,
      });

      await pumpApp(tester, firestore: firestore, auth: auth, functions: functions);
      expect(find.byType(HomeScreen), findsOneWidget);

      await tapText(tester, 'Issues');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Dirty dishes'), findsOneWidget);

      await tapText(tester, 'Dirty dishes');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.textContaining('Claim Issue'), findsOneWidget);
      await tapTextAndWait(tester, 'Claim Issue (+50 pts)');

      expect(find.text('Mark Resolved'), findsOneWidget);
      await tester.tap(find.text('Mark Resolved'));
      await tester.pumpAndSettle();
      await tapTextAndWait(tester, 'Confirm Resolution');

      final issuesSnap = await firestore
          .collection('houses/$houseId/issues')
          .get();
      expect(issuesSnap.docs.first.data()['status'], 'resolved');
      expect(issuesSnap.docs.first.data()['resolvedBy'], uid);
    });
  });

  // ── Settings / Admin Callables ─────────────────────────────────

  group('Settings', () {
    testWidgets('updateHouse changes name', (tester) async {
      await createTestUser('alice@test.com', 'password123');
      final result = await functions.httpsCallable('createHouse').call({
        'name': 'Old Name',
        'displayName': 'Alice',
        'timezone': 'Europe/Paris',
        'rooms': ['Kitchen'],
      });
      final houseId = result.data['houseId'] as String;

      await functions.httpsCallable('updateHouse').call({
        'houseId': houseId,
        'name': 'New Name',
      });

      final doc = await firestore.doc('houses/$houseId').get();
      expect(doc.data()!['name'], 'New Name');

      await pumpApp(tester, firestore: firestore, auth: auth, functions: functions);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('promote and remove member', (tester) async {
      await createTestUser('alice@test.com', 'password123');

      final createResult = await functions.httpsCallable('createHouse').call({
        'name': 'Admin House',
        'displayName': 'Alice',
        'timezone': 'Europe/Paris',
        'rooms': ['Kitchen'],
      });
      final houseId = createResult.data['houseId'] as String;
      final houseDoc = await firestore.doc('houses/$houseId').get();
      final inviteCode = houseDoc.data()!['inviteCode'] as String;

      await signOutTestUser();
      final uid2 = (await createTestUser('bob@test.com', 'password123')).user!.uid;

      await functions.httpsCallable('joinHouse').call({
        'inviteCode': inviteCode,
        'displayName': 'Bob',
      });

      await signOutTestUser();
      await signInTestUser('alice@test.com', 'password123');

      await functions.httpsCallable('updateMemberRole').call({
        'houseId': houseId,
        'targetUid': uid2,
        'newRole': 'admin',
      });
      var memberDoc = await firestore
          .doc('houses/$houseId/members/$uid2')
          .get();
      expect(memberDoc.data()!['role'], 'admin');

      await functions.httpsCallable('removeMember').call({
        'houseId': houseId,
        'targetUid': uid2,
      });
      memberDoc = await firestore
          .doc('houses/$houseId/members/$uid2')
          .get();
      expect(memberDoc.exists, false);

      await pumpApp(tester, firestore: firestore, auth: auth, functions: functions);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('leaveHouse removes member', (tester) async {
      await createTestUser('alice@test.com', 'password123');

      final result = await functions.httpsCallable('createHouse').call({
        'name': 'Temp House',
        'displayName': 'Alice',
        'timezone': 'Europe/Paris',
        'rooms': ['Kitchen'],
      });
      final houseId = result.data['houseId'] as String;
      final uid = auth.currentUser!.uid;

      await functions.httpsCallable('leaveHouse').call({
        'houseId': houseId,
      });

      final memberDoc = await firestore
          .doc('houses/$houseId/members/$uid')
          .get();
      expect(memberDoc.exists, false);

      await pumpApp(tester, firestore: firestore, auth: auth, functions: functions);
      expect(find.byType(HouseChoiceScreen), findsOneWidget);
    });
  });

  // ── Deep Clean ─────────────────────────────────────────────────

  group('Deep Clean', () {
    testWidgets('claimRoom and completeRoom callables', (tester) async {
      await createTestUser('alice@test.com', 'password123');

      final result = await functions.httpsCallable('createHouse').call({
        'name': 'Clean House',
        'displayName': 'Alice',
        'timezone': 'Europe/Paris',
        'rooms': ['Kitchen', 'Bathroom'],
      });
      final houseId = result.data['houseId'] as String;
      final uid = auth.currentUser!.uid;

      final dcRef = firestore
          .collection('houses/$houseId/deepCleans')
          .doc();
      final now = DateTime.now();
      await dcRef.set({
        'createdAt': Timestamp.fromDate(now),
        'deadline': Timestamp.fromDate(now.add(const Duration(days: 7))),
        'status': 'active',
        'assignments': {
          'Kitchen': {'uid': null, 'completedAt': null, 'points': 100},
          'Bathroom': {'uid': null, 'completedAt': null, 'points': 100},
        },
      });

      await functions.httpsCallable('claimRoom').call({
        'houseId': houseId,
        'cleanId': dcRef.id,
        'roomName': 'Kitchen',
      });
      var dc = await dcRef.get();
      expect((dc.data()!['assignments']['Kitchen'] as Map)['uid'], uid);

      await functions.httpsCallable('completeRoom').call({
        'houseId': houseId,
        'cleanId': dcRef.id,
        'roomName': 'Kitchen',
      });
      dc = await dcRef.get();
      expect((dc.data()!['assignments']['Kitchen'] as Map)['completedAt'], isNotNull);

      await pumpApp(tester, firestore: firestore, auth: auth, functions: functions);
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  // ── Home Feed ──────────────────────────────────────────────────

  group('Home Feed', () {
    testWidgets('momentum card for 0 resolved', (tester) async {
      await createTestUser('alice@test.com', 'password123');
      await functions.httpsCallable('createHouse').call({
        'name': 'Feed House',
        'displayName': 'Alice',
        'timezone': 'Europe/Paris',
        'rooms': ['Kitchen'],
      });

      await pumpApp(tester, firestore: firestore, auth: auth, functions: functions);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.textContaining('get started'), findsOneWidget);
    });

    testWidgets('activity subcollection is queryable', (tester) async {
      await createTestUser('alice@test.com', 'password123');
      final result = await functions.httpsCallable('createHouse').call({
        'name': 'Activity House',
        'displayName': 'Alice',
        'timezone': 'Europe/Paris',
        'rooms': ['Kitchen'],
      });
      final houseId = result.data['houseId'] as String;
      final uid = auth.currentUser!.uid;

      await seedDocument('houses/$houseId/activity/badge1', {
        'type': 'badgeEarned',
        'uid': uid,
        'displayName': 'Alice',
        'detail': 'First Blood',
        'createdAt': Timestamp.now(),
      });

      final snap = await firestore
          .collection('houses/$houseId/activity')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();
      expect(snap.docs.length, 1);
      expect(snap.docs.first.data()['detail'], 'First Blood');

      await pumpApp(tester, firestore: firestore, auth: auth, functions: functions);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('deep clean current month doc is queryable for nudge', (tester) async {
      await createTestUser('alice@test.com', 'password123');
      final result = await functions.httpsCallable('createHouse').call({
        'name': 'Nudge House',
        'displayName': 'Alice',
        'timezone': 'Europe/Paris',
        'rooms': ['Kitchen'],
      });
      final houseId = result.data['houseId'] as String;

      final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
      await firestore
          .doc('houses/$houseId/deepCleans/$currentMonth')
          .set({
        'createdAt': Timestamp.now(),
        'deadline':
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
        'status': 'active',
        'assignments': {
          'Kitchen': {'uid': null, 'fromVolunteer': false, 'completed': false},
        },
      });

      final doc = await firestore
          .doc('houses/$houseId/deepCleans/$currentMonth')
          .get();
      expect(doc.exists, true);
      final assignments = doc.data()!['assignments'] as Map<String, dynamic>;
      final unclaimed = assignments.values
          .where((r) => (r as Map<String, dynamic>)['uid'] == null)
          .length;
      expect(unclaimed, 1);

      await pumpApp(tester, firestore: firestore, auth: auth, functions: functions);
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  // ── Demo Flow ─────────────────────────────────────────────────

  group('Demo Flow', () {
    testWidgets('explore with demo data seeds house and exit cleans up', (tester) async {
      await pumpApp(tester, firestore: firestore, auth: auth, functions: functions);

      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.text('Explore with demo data'), findsOneWidget);

      await tester.tap(find.text('Explore with demo data'));
      await waitForAsync(tester, find.byType(HomeScreen),
          timeout: const Duration(seconds: 30));

      expect(find.textContaining('Appart Rue Exemple'), findsOneWidget);

      await tapText(tester, 'Profile');
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tapText(tester, 'Exit Demo');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Exit Demo').last);
      await tester.pumpAndSettle();

      await waitForAsync(tester, find.byType(WelcomeScreen),
          timeout: const Duration(seconds: 30));
      expect(find.text('Explore with demo data'), findsOneWidget);
    });
  });
}
