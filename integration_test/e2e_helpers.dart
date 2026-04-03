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
import 'package:macoloc/src/providers/auth_provider.dart';
import 'package:macoloc/src/providers/house_provider.dart';

const _firestoreHost = 'localhost';
const _firestorePort = 8080;
const _authPort = 9099;
const _functionsPort = 5001;
const _storagePort = 9199;
const _projectId = 'demo-macoloc';

/// Initialize Firebase and connect singletons to emulators. Call ONCE per process.
Future<({
  FirebaseFirestore firestore,
  FirebaseAuth auth,
  FirebaseFunctions functions,
})> connectEmulators() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.web.copyWith(projectId: _projectId),
  );

  final firestore = FirebaseFirestore.instance;
  firestore.useFirestoreEmulator(_firestoreHost, _firestorePort);

  final auth = FirebaseAuth.instance;
  await auth.useAuthEmulator(_firestoreHost, _authPort);

  final functions = FirebaseFunctions.instance;
  functions.useFunctionsEmulator(_firestoreHost, _functionsPort);

  await FirebaseStorage.instance.useStorageEmulator(_firestoreHost, _storagePort);

  return (firestore: firestore, auth: auth, functions: functions);
}

/// Clear all Firestore data via emulator REST API.
Future<void> clearFirestore() async {
  final url = Uri.parse(
    'http://$_firestoreHost:$_firestorePort/emulator/v1/projects/$_projectId/databases/(default)/documents',
  );
  await http.delete(url);
}

/// Clear all Auth users via emulator REST API.
Future<void> clearAuth() async {
  final url = Uri.parse(
    'http://$_firestoreHost:$_authPort/emulator/v1/projects/$_projectId/accounts',
  );
  await http.delete(url);
}

/// Reset emulator state (both Auth and Firestore).
Future<void> resetEmulators() async {
  // Sign out first so the SDK doesn't hold a stale token
  try {
    await FirebaseAuth.instance.signOut();
    await FirebaseAuth.instance
        .authStateChanges()
        .firstWhere((user) => user == null)
        .timeout(const Duration(seconds: 5), onTimeout: () => null);
  } catch (_) {}
  await Future.wait([clearFirestore(), clearAuth()]);
}

/// Build a ProviderContainer with emulator instances injected.
ProviderContainer buildTestContainer({
  required FirebaseFirestore firestore,
  required FirebaseAuth auth,
  required FirebaseFunctions functions,
}) {
  return ProviderContainer(
    overrides: [
      firebaseInitializedProvider.overrideWith((_) => true),
      firebaseAuthProvider.overrideWithValue(auth),
      firestoreProvider.overrideWithValue(firestore),
      firebaseFunctionsProvider.overrideWithValue(functions),
    ],
  );
}

/// Pump the app with injected emulator providers. Returns the container.
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  required FirebaseFirestore firestore,
  required FirebaseAuth auth,
  required FirebaseFunctions functions,
}) async {
  final container = buildTestContainer(
    firestore: firestore,
    auth: auth,
    functions: functions,
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaColocApp(),
    ),
  );

  // Let async providers settle: auth state → house query → router redirect
  for (var i = 0; i < 15; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
  await tester.pumpAndSettle();

  return container;
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
  await tester.pumpAndSettle(const Duration(milliseconds: 500), EnginePhase.sendSemanticsUpdate, timeout);
}

/// Wait until a finder matches at least one widget, pumping in between.
Future<void> waitFor(WidgetTester tester, Finder finder, {Duration timeout = const Duration(seconds: 15)}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 300));
    if (finder.evaluate().isNotEmpty) return;
  }
  await tester.pumpAndSettle();
  if (finder.evaluate().isEmpty) {
    throw TestFailure('waitFor timed out after $timeout looking for $finder');
  }
}

/// Wait for a widget using runAsync to allow real I/O (Firestore streams).
Future<void> waitForAsync(WidgetTester tester, Finder finder, {Duration timeout = const Duration(seconds: 30)}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 500)));
    await tester.pump();
    if (finder.evaluate().isNotEmpty) return;
  }
  await tester.pumpAndSettle();
  if (finder.evaluate().isEmpty) {
    throw TestFailure('waitForAsync timed out after $timeout looking for $finder');
  }
}

/// Seed a Firestore document directly.
Future<void> seedDocument(String path, Map<String, dynamic> data) async {
  await FirebaseFirestore.instance.doc(path).set(data);
}

/// Read a Firestore document.
Future<Map<String, dynamic>?> readDocument(String path) async {
  final doc = await FirebaseFirestore.instance.doc(path).get();
  return doc.data();
}

/// Extension to copy FirebaseOptions with overridden fields.
extension FirebaseOptionsCopy on FirebaseOptions {
  FirebaseOptions copyWith({String? projectId}) {
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId ?? this.projectId,
      authDomain: authDomain,
      storageBucket: storageBucket,
      measurementId: measurementId,
    );
  }
}
