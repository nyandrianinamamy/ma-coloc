import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/house.dart';
import 'auth_provider.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseFunctionsProvider = Provider<FirebaseFunctions>((ref) {
  return FirebaseFunctions.instance;
});

/// Queries Firestore for the first house where the current user is a member.
/// This is the bootstrap source of truth — survives app restarts.
/// Returns null if user has no house (needs onboarding).
final currentHouseIdProvider = FutureProvider<String?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return null;

  final db = ref.watch(firestoreProvider);
  final query = await db
      .collection('houses')
      .where('members', arrayContains: user.uid)
      .limit(1)
      .get();

  if (query.docs.isEmpty) return null;
  return query.docs.first.id;
});

/// Streams the current house document.
final currentHouseProvider = StreamProvider<House?>((ref) {
  final houseIdAsync = ref.watch(currentHouseIdProvider);
  final houseId = houseIdAsync.valueOrNull;
  if (houseId == null) return Stream.value(null);

  return ref
      .watch(firestoreProvider)
      .collection('houses')
      .doc(houseId)
      .snapshots()
      .map((doc) => doc.exists ? House.fromFirestore(doc) : null);
});

/// Actions for house creation and joining.
final houseActionsProvider =
    NotifierProvider<HouseActions, AsyncValue<void>>(HouseActions.new);

class HouseActions extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<String> createHouse({
    required String name,
    required String displayName,
    required String timezone,
    required List<String> rooms,
  }) async {
    final functions = ref.read(firebaseFunctionsProvider);
    final result =
        await functions.httpsCallable('createHouse').call<Map<String, dynamic>>({
      'name': name,
      'displayName': displayName,
      'timezone': timezone,
      'rooms': rooms,
    });
    final houseId = result.data['houseId'] as String;
    // Invalidate the house ID provider so it re-queries Firestore
    ref.invalidate(currentHouseIdProvider);
    return houseId;
  }

  Future<String> joinHouse({
    required String inviteCode,
    required String displayName,
    String? avatarUrl,
  }) async {
    final functions = ref.read(firebaseFunctionsProvider);
    final result =
        await functions.httpsCallable('joinHouse').call<Map<String, dynamic>>({
      'inviteCode': inviteCode,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
    });
    final houseId = result.data['houseId'] as String;
    ref.invalidate(currentHouseIdProvider);
    return houseId;
  }

  Future<void> leaveHouse(String houseId) async {
    final functions = ref.read(firebaseFunctionsProvider);
    await functions.httpsCallable('leaveHouse').call({'houseId': houseId});
    ref.invalidate(currentHouseIdProvider);
  }

  Future<String> seedDemoHouse() async {
    final functions = ref.read(firebaseFunctionsProvider);
    final result = await functions
        .httpsCallable('seedDemoHouse')
        .call<Map<String, dynamic>>({});
    final houseId = result.data['houseId'] as String;
    ref.invalidate(currentHouseIdProvider);
    return houseId;
  }

  Future<void> cleanupDemoHouse(String houseId) async {
    // Invalidate before calling the function so the Firestore stream stops
    // listening to the house document. The Cloud Function deletes the auth
    // account, which would otherwise cause a permission-denied error on the
    // active stream. The router handles anonymous+no-house → /welcome now.
    ref.invalidate(currentHouseIdProvider);
    final functions = ref.read(firebaseFunctionsProvider);
    await functions
        .httpsCallable('cleanupDemoHouse')
        .call({'houseId': houseId});
  }
}
