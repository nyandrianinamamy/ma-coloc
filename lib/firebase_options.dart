// Firebase options supporting Android, iOS, and Web (emulator-only).
// To use real credentials, run: flutterfire configure --project=macoloc-app

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  /// Returns true when credentials are still placeholders.
  /// Web and emulator configs return false because the demo-macoloc config is
  /// used for E2E tests. When real credentials are added via
  /// `flutterfire configure`, this file will be regenerated.
  static bool get isPlaceholder => currentPlatform.projectId != 'demo-macoloc' && android.apiKey == 'TODO';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        // Use emulator config when real credentials aren't configured yet
        return ios.apiKey == 'TODO' ? iosEmulator : ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'fake-api-key',
    appId: '1:000000000000:web:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-macoloc',
    storageBucket: 'demo-macoloc.appspot.com',
    authDomain: 'demo-macoloc.firebaseapp.com',
  );

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

  /// iOS emulator-only config for E2E tests with demo-macoloc project.
  /// API key must start with 'AIzaSy' to pass native SDK format validation.
  static const FirebaseOptions iosEmulator = FirebaseOptions(
    apiKey: 'AIzaSyDemoKeyForEmulatorTestingOnly0000',
    appId: '1:000000000000:ios:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-macoloc',
    storageBucket: 'demo-macoloc.appspot.com',
    iosBundleId: 'dev.mamy-r.macoloc',
  );
}
