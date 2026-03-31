import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';
import 'house_provider.dart';

final settingsActionsProvider =
    NotifierProvider<SettingsActions, AsyncValue<void>>(SettingsActions.new);

class SettingsActions extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  FirebaseFunctions get _functions => ref.read(firebaseFunctionsProvider);
  FirebaseFirestore get _db => ref.read(firestoreProvider);
  String? get _uid => ref.read(authStateProvider).valueOrNull?.uid;

  Future<void> updateHouseName({
    required String houseId,
    required String name,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _functions.httpsCallable('updateHouse').call({
        'houseId': houseId,
        'name': name,
      });
    });
  }

  Future<void> removeMember({
    required String houseId,
    required String targetUid,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _functions.httpsCallable('removeMember').call({
        'houseId': houseId,
        'targetUid': targetUid,
      });
    });
  }

  Future<void> updateMemberRole({
    required String houseId,
    required String targetUid,
    required String newRole,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _functions.httpsCallable('updateMemberRole').call({
        'houseId': houseId,
        'targetUid': targetUid,
        'newRole': newRole,
      });
    });
  }

  Future<void> toggleNotifications({
    required String houseId,
    required bool enabled,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _db
          .collection('houses/$houseId/members')
          .doc(uid)
          .update({'notificationsEnabled': enabled});
    });
  }
}
