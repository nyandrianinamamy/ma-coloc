// Single entry point for all E2E tests.
// Flutter web integration tests require running all tests in one file
// because each flutter drive invocation starts a new browser session.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:macoloc/src/features/onboarding/sign_in_screen.dart';
import 'package:macoloc/src/features/onboarding/house_choice_screen.dart';
import 'package:macoloc/src/features/home/home_screen.dart';

import 'e2e_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initFirebaseForTest();
  });

  setUp(() async {
    await resetEmulators();
  });

  // ── Auth Flow ──────────────────────────────────────────────────

  group('Auth', () {
    testWidgets('unauthenticated user sees sign-in', (tester) async {
      await pumpApp(tester);
      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.text('MaColoc'), findsOneWidget);
    });

    testWidgets('sign-up navigates to onboarding', (tester) async {
      await pumpApp(tester);

      await tapText(tester, "Don't have an account? Sign up");
      await enterTextField(tester, 'Email', 'alice@test.com');
      await enterTextField(tester, 'Password', 'password123');

      await tester.tap(find.text('Create Account'));
      await waitFor(tester, find.byType(HouseChoiceScreen), timeout: const Duration(seconds: 30));
    });

    testWidgets('sign-in with existing user', (tester) async {
      await createTestUser('bob@test.com', 'password123');
      await signOutTestUser();

      await pumpApp(tester);
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
      await pumpApp(tester);
      expect(find.byType(HouseChoiceScreen), findsOneWidget);

      final result = await FirebaseFunctions.instance
          .httpsCallable('createHouse')
          .call({
        'name': 'Test Apt',
        'displayName': 'Alice',
        'timezone': 'Europe/Paris',
        'rooms': ['Kitchen'],
      });
      final houseId = result.data['houseId'] as String;

      // Verify house + member in Firestore
      final houseDoc =
          await FirebaseFirestore.instance.doc('houses/$houseId').get();
      expect(houseDoc.data()!['name'], 'Test Apt');
      expect(houseDoc.data()!['inviteCode'], isNotEmpty);

      final memberDoc = await FirebaseFirestore.instance
          .doc('houses/$houseId/members/${cred.user!.uid}')
          .get();
      expect(memberDoc.data()!['role'], 'admin');

      // Re-pump → should route to home
      await pumpApp(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('joinHouse callable adds second member', (tester) async {
      await createTestUser('alice@test.com', 'password123');
      final functions = FirebaseFunctions.instance;

      final createResult =
          await functions.httpsCallable('createHouse').call({
        'name': 'Shared Flat',
        'displayName': 'Alice',
        'timezone': 'Europe/Paris',
        'rooms': ['Kitchen'],
      });
      final houseId = createResult.data['houseId'] as String;

      final houseDoc =
          await FirebaseFirestore.instance.doc('houses/$houseId').get();
      final inviteCode = houseDoc.data()!['inviteCode'] as String;

      await signOutTestUser();
      await createTestUser('bob@test.com', 'password123');

      await functions.httpsCallable('joinHouse').call({
        'inviteCode': inviteCode,
        'displayName': 'Bob',
      });

      final membersSnap = await FirebaseFirestore.instance
          .collection('houses/$houseId/members')
          .get();
      expect(membersSnap.docs.length, 2);

      await pumpApp(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  // ── Issue Lifecycle ────────────────────────────────────────────

  group('Issues', () {
    testWidgets('seed issue, navigate, claim, resolve', (tester) async {
      // Setup: user + house programmatically
      await createTestUser('alice@test.com', 'password123');
      final result = await FirebaseFunctions.instance
          .httpsCallable('createHouse')
          .call({
        'name': 'Issue House',
        'displayName': 'Alice',
        'timezone': 'Europe/Paris',
        'rooms': ['Kitchen'],
      });
      final houseId = result.data['houseId'] as String;
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Seed an issue
      await FirebaseFirestore.instance
          .collection('houses/$houseId/issues')
          .add({
        'type': 'chore',
        'title': 'Dirty dishes',
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'open',
        'points': 50,
        'anonymous': false,
      });

      await pumpApp(tester);
      expect(find.byType(HomeScreen), findsOneWidget);

      // Navigate to Issues tab
      await tapText(tester, 'Issues');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify issue appears
      expect(find.text('Dirty dishes'), findsOneWidget);

      // Tap issue → detail
      await tapText(tester, 'Dirty dishes');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Claim
      expect(find.textContaining('Claim Issue'), findsOneWidget);
      await tapTextAndWait(tester, 'Claim Issue (+50 pts)');

      // Resolve
      expect(find.text('Mark Resolved'), findsOneWidget);
      await tester.tap(find.text('Mark Resolved'));
      await tester.pumpAndSettle();
      await tapTextAndWait(tester, 'Confirm Resolution');

      // Verify Firestore
      final issuesSnap = await FirebaseFirestore.instance
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
      final result = await FirebaseFunctions.instance
          .httpsCallable('createHouse')
          .call({
        'name': 'Old Name',
        'displayName': 'Alice',
        'timezone': 'Europe/Paris',
        'rooms': ['Kitchen'],
      });
      final houseId = result.data['houseId'] as String;

      await FirebaseFunctions.instance.httpsCallable('updateHouse').call({
        'houseId': houseId,
        'name': 'New Name',
      });

      final doc =
          await FirebaseFirestore.instance.doc('houses/$houseId').get();
      expect(doc.data()!['name'], 'New Name');

      await pumpApp(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('promote and remove member', (tester) async {
      await createTestUser('alice@test.com', 'password123');
      final functions = FirebaseFunctions.instance;

      final createResult =
          await functions.httpsCallable('createHouse').call({
        'name': 'Admin House',
        'displayName': 'Alice',
        'timezone': 'Europe/Paris',
        'rooms': ['Kitchen'],
      });
      final houseId = createResult.data['houseId'] as String;
      final houseDoc =
          await FirebaseFirestore.instance.doc('houses/$houseId').get();
      final inviteCode = houseDoc.data()!['inviteCode'] as String;

      await signOutTestUser();
      final uid2 = (await createTestUser('bob@test.com', 'password123')).user!.uid;

      await functions.httpsCallable('joinHouse').call({
        'inviteCode': inviteCode,
        'displayName': 'Bob',
      });

      // Switch back to admin
      await signOutTestUser();
      await signInTestUser('alice@test.com', 'password123');

      // Promote bob
      await functions.httpsCallable('updateMemberRole').call({
        'houseId': houseId,
        'targetUid': uid2,
        'newRole': 'admin',
      });
      var memberDoc = await FirebaseFirestore.instance
          .doc('houses/$houseId/members/$uid2')
          .get();
      expect(memberDoc.data()!['role'], 'admin');

      // Remove bob
      await functions.httpsCallable('removeMember').call({
        'houseId': houseId,
        'targetUid': uid2,
      });
      memberDoc = await FirebaseFirestore.instance
          .doc('houses/$houseId/members/$uid2')
          .get();
      expect(memberDoc.exists, false);

      await pumpApp(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('leaveHouse removes member', (tester) async {
      await createTestUser('alice@test.com', 'password123');
      final functions = FirebaseFunctions.instance;

      final result =
          await functions.httpsCallable('createHouse').call({
        'name': 'Temp House',
        'displayName': 'Alice',
        'timezone': 'Europe/Paris',
        'rooms': ['Kitchen'],
      });
      final houseId = result.data['houseId'] as String;
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await functions.httpsCallable('leaveHouse').call({
        'houseId': houseId,
      });

      final memberDoc = await FirebaseFirestore.instance
          .doc('houses/$houseId/members/$uid')
          .get();
      expect(memberDoc.exists, false);

      await pumpApp(tester);
      // No house → should be on onboarding
      expect(find.byType(HouseChoiceScreen), findsOneWidget);
    });
  });

  // ── Deep Clean ─────────────────────────────────────────────────

  group('Deep Clean', () {
    testWidgets('claimRoom and completeRoom callables', (tester) async {
      await createTestUser('alice@test.com', 'password123');
      final functions = FirebaseFunctions.instance;

      final result =
          await functions.httpsCallable('createHouse').call({
        'name': 'Clean House',
        'displayName': 'Alice',
        'timezone': 'Europe/Paris',
        'rooms': ['Kitchen', 'Bathroom'],
      });
      final houseId = result.data['houseId'] as String;
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Seed deep clean with 'assignments' schema (matches callable expectations)
      final dcRef = FirebaseFirestore.instance
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

      // Claim
      await functions.httpsCallable('claimRoom').call({
        'houseId': houseId,
        'cleanId': dcRef.id,
        'roomName': 'Kitchen',
      });
      var dc = await dcRef.get();
      expect((dc.data()!['assignments']['Kitchen'] as Map)['uid'], uid);

      // Complete
      await functions.httpsCallable('completeRoom').call({
        'houseId': houseId,
        'cleanId': dcRef.id,
        'roomName': 'Kitchen',
      });
      dc = await dcRef.get();
      expect((dc.data()!['assignments']['Kitchen'] as Map)['completedAt'], isNotNull);

      await pumpApp(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  // ── Home Feed ──────────────────────────────────────────────────

  group('Home Feed', () {
    testWidgets('momentum card for 0 resolved', (tester) async {
      await createTestUser('alice@test.com', 'password123');
      await FirebaseFunctions.instance
          .httpsCallable('createHouse')
          .call({
        'name': 'Feed House',
        'displayName': 'Alice',
        'timezone': 'Europe/Paris',
        'rooms': ['Kitchen'],
      });

      await pumpApp(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.textContaining('get started'), findsOneWidget);
    });

    testWidgets('activity subcollection is queryable', (tester) async {
      await createTestUser('alice@test.com', 'password123');
      final result = await FirebaseFunctions.instance
          .httpsCallable('createHouse')
          .call({
        'name': 'Activity House',
        'displayName': 'Alice',
        'timezone': 'Europe/Paris',
        'rooms': ['Kitchen'],
      });
      final houseId = result.data['houseId'] as String;
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Seed activity
      await seedDocument('houses/$houseId/activity/badge1', {
        'type': 'badgeEarned',
        'uid': uid,
        'displayName': 'Alice',
        'detail': 'First Blood',
        'createdAt': Timestamp.now(),
      });

      // Verify activity is queryable from Firestore (same query the provider uses)
      final snap = await FirebaseFirestore.instance
          .collection('houses/$houseId/activity')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();
      expect(snap.docs.length, 1);
      expect(snap.docs.first.data()['detail'], 'First Blood');
      expect(snap.docs.first.data()['type'], 'badgeEarned');

      await pumpApp(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('deep clean current month doc is queryable for nudge', (tester) async {
      await createTestUser('alice@test.com', 'password123');
      final result = await FirebaseFunctions.instance
          .httpsCallable('createHouse')
          .call({
        'name': 'Nudge House',
        'displayName': 'Alice',
        'timezone': 'Europe/Paris',
        'rooms': ['Kitchen'],
      });
      final houseId = result.data['houseId'] as String;

      // Seed deep clean using current month doc ID (matches currentDeepCleanProvider)
      final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
      await FirebaseFirestore.instance
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

      // Verify deep clean doc is readable (same path the provider queries)
      final doc = await FirebaseFirestore.instance
          .doc('houses/$houseId/deepCleans/$currentMonth')
          .get();
      expect(doc.exists, true);
      final assignments = doc.data()!['assignments'] as Map<String, dynamic>;
      final unclaimed = assignments.values
          .where((r) => (r as Map<String, dynamic>)['uid'] == null)
          .length;
      expect(unclaimed, 1);

      await pumpApp(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
