import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:macoloc/src/features/home/home_screen.dart';
import 'package:macoloc/src/features/onboarding/house_choice_screen.dart';
import 'package:macoloc/src/features/onboarding/house_created_screen.dart';

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
    testWidgets('create house flow end-to-end', (tester) async {
      // Sign up a fresh user
      await createTestUser('alice@test.com', 'password123');

      await pumpApp(tester);

      // Should be on onboarding
      expect(find.byType(HouseChoiceScreen), findsOneWidget);

      // Tap "Create a House"
      await tapText(tester, 'Create a House');

      // Fill in house creation form
      await enterTextField(tester, 'Your Display Name', 'Alice');
      await enterTextField(tester, 'House Name', 'Test Apartment');

      // Submit the form
      await tapTextAndWait(tester, 'Create House', timeout: const Duration(seconds: 10));

      // Should navigate to house-created screen
      expect(find.byType(HouseCreatedScreen), findsOneWidget);
      expect(find.text('Test Apartment created!'), findsOneWidget);

      // Verify invite code is displayed
      expect(find.text('Share this invite code with your roommates:'), findsOneWidget);

      // Tap "Go to Home"
      await tapTextAndWait(tester, 'Go to Home');

      // Should be on home screen
      expect(find.byType(HomeScreen), findsOneWidget);

      // Verify Firestore: house document exists
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final housesSnap = await FirebaseFirestore.instance
          .collection('houses')
          .where('members', arrayContains: uid)
          .get();
      expect(housesSnap.docs.length, 1);
      expect(housesSnap.docs.first.data()['name'], 'Test Apartment');
    });
  });

  group('Onboarding: Join house', () {
    testWidgets('second user joins with invite code', (tester) async {
      // User 1 creates a house
      final cred1 = await createTestUser('alice@test.com', 'password123');

      await pumpApp(tester);

      // Create house through UI
      await tapText(tester, 'Create a House');
      await enterTextField(tester, 'Your Display Name', 'Alice');
      await enterTextField(tester, 'House Name', 'Shared Flat');
      await tapTextAndWait(tester, 'Create House', timeout: const Duration(seconds: 10));

      // Get the invite code from Firestore
      final housesSnap = await FirebaseFirestore.instance
          .collection('houses')
          .where('members', arrayContains: cred1.user!.uid)
          .get();
      final inviteCode = housesSnap.docs.first.data()['inviteCode'] as String;

      // Sign out user 1
      await signOutTestUser();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Create user 2
      await createTestUser('bob@test.com', 'password123');
      await pumpApp(tester);

      // Should be on onboarding (no house for user 2)
      expect(find.byType(HouseChoiceScreen), findsOneWidget);

      // Join with invite code
      await tapText(tester, 'Join with Invite Code');
      await enterTextField(tester, 'Invite Code', inviteCode);
      await enterTextField(tester, 'Your Display Name', 'Bob');
      await tapTextAndWait(tester, 'Join House', timeout: const Duration(seconds: 10));

      // Should be on home screen
      expect(find.byType(HomeScreen), findsOneWidget);

      // Verify Firestore: both users are members
      final houseDoc = housesSnap.docs.first.reference;
      final membersSnap = await houseDoc.collection('members').get();
      expect(membersSnap.docs.length, 2);
    });
  });
}
