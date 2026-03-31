import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';
import 'house_provider.dart';

final fcmProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});

final notificationSetupProvider = FutureProvider<void>((ref) async {
  final messaging = ref.watch(fcmProvider);
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return;

  final houseIdAsync = ref.watch(currentHouseIdProvider);
  final houseId = houseIdAsync.valueOrNull;
  if (houseId == null) return;

  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus != AuthorizationStatus.authorized &&
      settings.authorizationStatus != AuthorizationStatus.provisional) {
    return;
  }

  final token = await messaging.getToken();
  if (token != null) {
    final db = ref.read(firestoreProvider);
    await db
        .collection('houses/$houseId/members')
        .doc(user.uid)
        .update({'fcmToken': token});
  }

  messaging.onTokenRefresh.listen((newToken) async {
    final db = ref.read(firestoreProvider);
    await db
        .collection('houses/$houseId/members')
        .doc(user.uid)
        .update({'fcmToken': newToken});
  });
});
