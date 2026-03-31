import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'firebase_options.dart';

/// Whether Firebase was successfully initialized at startup.
/// Providers check this before accessing Firebase services.
final firebaseInitializedProvider = StateProvider<bool>((_) => false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseReady = false;
  if (!DefaultFirebaseOptions.isPlaceholder) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
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
