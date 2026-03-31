// TODO: Replace with real credentials by running:
//   flutterfire configure --project=macoloc-app
// Until then, Firebase.initializeApp is skipped at startup (see main.dart).

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  /// Returns true when credentials are still placeholders.
  static bool get isPlaceholder => android.apiKey == 'TODO';

  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not configured for this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'TODO',
    appId: 'TODO',
    messagingSenderId: 'TODO',
    projectId: 'macoloc-app',
    storageBucket: 'macoloc-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'TODO',
    appId: 'TODO',
    messagingSenderId: 'TODO',
    projectId: 'macoloc-app',
    storageBucket: 'macoloc-app.firebasestorage.app',
    iosBundleId: 'com.macoloc.macoloc',
  );
}
