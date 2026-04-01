import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'app.dart';
import 'firebase_options.dart';

/// Whether Firebase was successfully initialized at startup.
/// Providers check this before accessing Firebase services.
final firebaseInitializedProvider = StateProvider<bool>((_) => false);

/// Set to true to force emulator usage even in profile/release builds.
const bool _forceEmulators = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseReady = false;
  if (!DefaultFirebaseOptions.isPlaceholder) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Only connect to emulators for demo-macoloc (E2E tests) or when forced.
    final useEmulators = _forceEmulators ||
        (kDebugMode &&
            DefaultFirebaseOptions.currentPlatform.projectId == 'demo-macoloc');
    if (useEmulators) {
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
      await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
    }

    firebaseReady = true;
  }

  runApp(
    ProviderScope(
      overrides: [
        firebaseInitializedProvider.overrideWith((_) => firebaseReady),
      ],
      child: const MaColocApp(),
    ),
  );
}
