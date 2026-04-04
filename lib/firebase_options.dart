// Firebase options supporting Android, iOS, and Web (emulator-only).
// To use real credentials, run: flutterfire configure --project=macoloc-app

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  /// Returns true when credentials are still placeholders.
  /// Web and emulator configs return false because the demo-macoloc config is
  /// used for E2E tests. When real credentials are added via
  /// `flutterfire configure`, this file will be regenerated.
  static bool get isPlaceholder => false;

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
    apiKey: 'AIzaSyDOu5kEpFSgP8Imft3WtW7trtBuypk3GfQ',
    appId: '1:53644947761:web:504f8e123eaaec09c3c010',
    messagingSenderId: '53644947761',
    projectId: 'ma-coloc-87f1b',
    authDomain: 'ma-coloc-87f1b.firebaseapp.com',
    storageBucket: 'ma-coloc-87f1b.firebasestorage.app',
    measurementId: 'G-6YFR0YKNP9',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDTG-8UKWIRen5LLGjrmn_wFn47WeYUNT8',
    appId: '1:53644947761:android:49fc8b4763ec54d6c3c010',
    messagingSenderId: '53644947761',
    projectId: 'ma-coloc-87f1b',
    storageBucket: 'ma-coloc-87f1b.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDGrn8ZOStH6oNUSgkR_v1K9-hvlMXhLew',
    appId: '1:53644947761:ios:8a1f3f37c7cf3adec3c010',
    messagingSenderId: '53644947761',
    projectId: 'ma-coloc-87f1b',
    storageBucket: 'ma-coloc-87f1b.firebasestorage.app',
    iosBundleId: 'dev.mamy-r.macoloc',
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