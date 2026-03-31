import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:macoloc/app.dart';
import 'package:macoloc/main.dart' show firebaseInitializedProvider;
import 'package:macoloc/firebase_options.dart';

const _firestoreHost = 'localhost';
const _firestorePort = 8080;
const _authPort = 9099;
const _functionsPort = 5001;
const _storagePort = 9199;

bool _firebaseInitialized = false;

/// Initialize Firebase and connect to emulators. Safe to call multiple times.
Future<void> initFirebaseForTest() async {
  if (_firebaseInitialized) return;

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.web,
  );

  // Connect all services to emulators
  await FirebaseAuth.instance.useAuthEmulator(_firestoreHost, _authPort);
  FirebaseFirestore.instance.useFirestoreEmulator(_firestoreHost, _firestorePort);
  FirebaseFunctions.instance.useFunctionsEmulator(_firestoreHost, _functionsPort);
  await FirebaseStorage.instance.useStorageEmulator(_firestoreHost, _storagePort);

  _firebaseInitialized = true;
}

/// Clear all Firestore data via emulator REST API.
Future<void> clearFirestore() async {
  final url = Uri.parse(
    'http://$_firestoreHost:$_firestorePort/emulator/v1/projects/demo-macoloc/databases/(default)/documents',
  );
  await http.delete(url);
}

/// Clear all Auth users via emulator REST API.
Future<void> clearAuth() async {
  final url = Uri.parse(
    'http://$_firestoreHost:$_authPort/emulator/v1/projects/demo-macoloc/accounts',
  );
  await http.delete(url);
}

/// Create a test user and return the UserCredential.
Future<UserCredential> createTestUser(String email, String password) async {
  return FirebaseAuth.instance.createUserWithEmailAndPassword(
    email: email,
    password: password,
  );
}

/// Sign in a test user.
Future<UserCredential> signInTestUser(String email, String password) async {
  return FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email,
    password: password,
  );
}

/// Sign out the current user.
Future<void> signOutTestUser() async {
  await FirebaseAuth.instance.signOut();
}

/// Pump the app and wait for it to settle. Returns the ProviderContainer.
Future<ProviderContainer> pumpApp(WidgetTester tester) async {
  final container = ProviderContainer(
    overrides: [
      firebaseInitializedProvider.overrideWith((_) => true),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaColocApp(),
    ),
  );

  // Let async providers (auth state, house query) settle
  await tester.pumpAndSettle(const Duration(seconds: 2));

  return container;
}

/// Convenience: clear all emulator state (Auth + Firestore).
Future<void> resetEmulators() async {
  // Sign out first to avoid stale auth state
  try {
    await FirebaseAuth.instance.signOut();
  } catch (_) {}
  await clearAuth();
  await clearFirestore();
}

/// Enter text into a TextField identified by its label.
Future<void> enterTextField(WidgetTester tester, String label, String text) async {
  final field = find.widgetWithText(TextField, label);
  await tester.enterText(field, text);
  await tester.pumpAndSettle();
}

/// Tap a widget containing the given text.
Future<void> tapText(WidgetTester tester, String text) async {
  final widget = find.text(text);
  await tester.tap(widget);
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

/// Tap a widget containing the given text, waiting longer for async operations.
Future<void> tapTextAndWait(WidgetTester tester, String text, {Duration timeout = const Duration(seconds: 5)}) async {
  final widget = find.text(text);
  await tester.tap(widget);
  // Pump with a timeout to allow async operations
  await tester.pumpAndSettle(const Duration(milliseconds: 500), EnginePhase.sendSemanticsUpdate, timeout);
}

/// Seed a Firestore document directly (for scheduled function side-effects).
Future<void> seedDocument(String path, Map<String, dynamic> data) async {
  await FirebaseFirestore.instance.doc(path).set(data);
}

/// Read a Firestore document.
Future<Map<String, dynamic>?> readDocument(String path) async {
  final doc = await FirebaseFirestore.instance.doc(path).get();
  return doc.data();
}
