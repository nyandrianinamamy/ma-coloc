import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/deep_clean.dart';
import 'house_provider.dart';

// ---------------------------------------------------------------------------
// Stream provider: current month's deep clean
// ---------------------------------------------------------------------------

final currentDeepCleanProvider =
    StreamProvider.family<DeepClean?, String>((ref, houseId) {
  final db = ref.watch(firestoreProvider);
  final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());

  return db
      .collection('houses/$houseId/deepCleans')
      .doc(currentMonth)
      .snapshots()
      .map((doc) => doc.exists ? DeepClean.fromFirestore(doc) : null);
});

// ---------------------------------------------------------------------------
// Deep clean actions (via callables)
// ---------------------------------------------------------------------------

final deepCleanActionsProvider =
    NotifierProvider<DeepCleanActions, AsyncValue<void>>(DeepCleanActions.new);

class DeepCleanActions extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  FirebaseFunctions get _functions => ref.read(firebaseFunctionsProvider);

  Future<void> claimRoom({
    required String houseId,
    required String cleanId,
    required String roomName,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _functions.httpsCallable('claimRoom').call({
        'houseId': houseId,
        'cleanId': cleanId,
        'roomName': roomName,
      });
    });
  }

  Future<void> completeRoom({
    required String houseId,
    required String cleanId,
    required String roomName,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _functions.httpsCallable('completeRoom').call({
        'houseId': houseId,
        'cleanId': cleanId,
        'roomName': roomName,
      });
    });
  }
}
