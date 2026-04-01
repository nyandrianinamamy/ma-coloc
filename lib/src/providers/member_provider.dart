import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/member.dart';
import 'auth_provider.dart';
import 'house_provider.dart';

// ---------------------------------------------------------------------------
// Stream provider: all members of a house
// ---------------------------------------------------------------------------

final membersStreamProvider =
    StreamProvider.family<List<Member>, String>((ref, houseId) {
  final db = ref.watch(firestoreProvider);

  return db
      .collection('houses/$houseId/members')
      .snapshots()
      .map((snap) => snap.docs.map(Member.fromFirestore).toList());
});

// ---------------------------------------------------------------------------
// UID → display name lookup
// ---------------------------------------------------------------------------

final memberDisplayNameProvider =
    Provider.family<String, (String houseId, String uid)>((ref, args) {
  final (houseId, uid) = args;
  final members = ref.watch(membersStreamProvider(houseId)).valueOrNull ?? [];
  final match = members.where((m) => m.id == uid);
  if (match.isNotEmpty) return match.first.displayName;
  return uid.length > 8 ? '${uid.substring(0, 8)}…' : uid;
});

// ---------------------------------------------------------------------------
// Presence actions
// ---------------------------------------------------------------------------

final presenceActionsProvider =
    NotifierProvider<PresenceActions, AsyncValue<void>>(PresenceActions.new);

class PresenceActions extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  FirebaseFirestore get _db => ref.read(firestoreProvider);
  String? get _uid => ref.read(authStateProvider).valueOrNull?.uid;

  Future<void> togglePresence({
    required String houseId,
    required Presence newPresence,
  }) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not authenticated');

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _db.collection('houses/$houseId/members').doc(uid).update({
        'presence': newPresence.name,
        'presenceUpdatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
