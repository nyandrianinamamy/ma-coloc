import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import 'house_provider.dart';

final dataManagementProvider =
    NotifierProvider<DataManagementNotifier, AsyncValue<void>>(
        DataManagementNotifier.new);

class DataManagementNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> deleteAccount() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final functions = ref.read(firebaseFunctionsProvider);
      await functions.httpsCallable('deleteAccount').call({});
      await ref.read(firebaseAuthProvider).signOut();
    });
  }

  Future<void> resetHouseData({
    required String houseId,
    required String scope,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final functions = ref.read(firebaseFunctionsProvider);
      await functions.httpsCallable('resetHouseData').call({
        'houseId': houseId,
        'scope': scope,
      });
    });
  }

  Future<int> purgeArchivedIssues({
    required String houseId,
    int? olderThanDays,
  }) async {
    state = const AsyncLoading();
    int deletedCount = 0;
    state = await AsyncValue.guard(() async {
      final functions = ref.read(firebaseFunctionsProvider);
      final result = await functions
          .httpsCallable('purgeArchivedIssues')
          .call<Map<String, dynamic>>({
        'houseId': houseId,
        if (olderThanDays != null) 'olderThanDays': olderThanDays,
      });
      deletedCount = (result.data['deletedCount'] as num?)?.toInt() ?? 0;
    });
    return deletedCount;
  }

  Future<void> clearLocalCache() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      await FirebaseFirestore.instance.terminate();
      await FirebaseFirestore.instance.clearPersistence();
    });
  }
}
