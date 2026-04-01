import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/issue.dart';
import 'auth_provider.dart';
import 'house_provider.dart';

// ---------------------------------------------------------------------------
// Enum & value objects
// ---------------------------------------------------------------------------

enum IssueTab { all, mine, open }

class IssueQueryParams {
  const IssueQueryParams({required this.houseId, required this.tab});

  final String houseId;
  final IssueTab tab;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IssueQueryParams &&
          runtimeType == other.runtimeType &&
          houseId == other.houseId &&
          tab == other.tab;

  @override
  int get hashCode => Object.hash(houseId, tab);
}

// ---------------------------------------------------------------------------
// Top-level filter helpers (exported for testing)
// ---------------------------------------------------------------------------

List<Issue> filterByType(List<Issue> issues, IssueType? type) {
  if (type == null) return issues;
  return issues.where((i) => i.type == type).toList();
}

List<Issue> filterBySearch(List<Issue> issues, String query) {
  if (query.isEmpty) return issues;
  final lower = query.toLowerCase();
  return issues
      .where((i) => i.title?.toLowerCase().contains(lower) ?? false)
      .toList();
}

// ---------------------------------------------------------------------------
// Stream providers
// ---------------------------------------------------------------------------

/// Streams a list of issues for a given house filtered by [IssueQueryParams].
/// Returns an empty list for the `mine` tab when the user is not authenticated.
final issuesStreamProvider =
    StreamProvider.family<List<Issue>, IssueQueryParams>((ref, params) {
  final db = ref.watch(firestoreProvider);
  final authState = ref.watch(authStateProvider);
  final uid = authState.valueOrNull?.uid;

  CollectionReference<Map<String, dynamic>> col =
      db.collection('houses/${params.houseId}/issues');

  Query<Map<String, dynamic>> query;
  switch (params.tab) {
    case IssueTab.all:
      query = col.orderBy('createdAt', descending: true).limit(50);
    case IssueTab.mine:
      if (uid == null) return Stream.value([]);
      query = col
          .where('assignedTo', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(50);
    case IssueTab.open:
      query = col
          .where('status', isEqualTo: 'open')
          .orderBy('createdAt', descending: true)
          .limit(50);
  }

  return query.snapshots().map(
        (snap) => snap.docs.map(Issue.fromFirestore).toList(),
      );
});

/// Streams a single issue document, or null if it does not exist.
final issueDetailProvider =
    StreamProvider.family<Issue?, (String houseId, String issueId)>(
        (ref, args) {
  final db = ref.watch(firestoreProvider);
  final (houseId, issueId) = args;

  return db
      .collection('houses/$houseId/issues')
      .doc(issueId)
      .snapshots()
      .map((doc) => doc.exists ? Issue.fromFirestore(doc) : null);
});

// ---------------------------------------------------------------------------
// Firebase Storage provider
// ---------------------------------------------------------------------------

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

// ---------------------------------------------------------------------------
// Issue actions
// ---------------------------------------------------------------------------

/// Notifier for create / claim / resolve / dispute / react actions on issues.
final issueActionsProvider =
    NotifierProvider<IssueActions, AsyncValue<void>>(IssueActions.new);

class IssueActions extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  FirebaseFirestore get _db => ref.read(firestoreProvider);
  FirebaseStorage get _storage => ref.read(firebaseStorageProvider);

  /// Returns null when no user is signed in.
  String? get _uid => ref.read(authStateProvider).valueOrNull?.uid;

  CollectionReference<Map<String, dynamic>> _issuesCol(String houseId) =>
      _db.collection('houses/$houseId/issues');

  Future<String?> _uploadPhoto(String path, XFile photo) async {
    final storageRef = _storage.ref(path);
    final bytes = await photo.readAsBytes();
    await storageRef.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return storageRef.getDownloadURL();
  }

  /// Creates a new issue and returns its Firestore document ID.
  Future<String> create({
    required String houseId,
    required IssueType type,
    String? title,
    String? description,
    bool anonymous = false,
    XFile? photo,
  }) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not authenticated');

    state = const AsyncLoading();

    String? issueId;
    try {
      final docRef = _issuesCol(houseId).doc();
      issueId = docRef.id;

      String? photoUrl;
      if (photo != null) {
        try {
          photoUrl = await _uploadPhoto(
            'houses/$houseId/issues/$issueId/photo.jpg',
            photo,
          );
        } catch (e) {
          debugPrint('Photo upload failed (continuing without photo): $e');
        }
      }

      final issue = Issue(
        id: issueId,
        type: type,
        title: title,
        description: description,
        photoUrl: photoUrl,
        createdBy: uid,
        anonymous: anonymous,
        createdAt: Timestamp.now(),
        points: Issue.pointsForType(type),
      );

      await docRef.set(issue.toJson());
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }

    return issueId;
  }

  Future<void> claim({
    required String houseId,
    required String issueId,
  }) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not authenticated');

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _issuesCol(houseId).doc(issueId).update({
        'assignedTo': uid,
        'assignedAt': FieldValue.serverTimestamp(),
        'status': 'in_progress',
      });
    });
  }

  Future<void> resolve({
    required String houseId,
    required String issueId,
    String? note,
    XFile? resolutionPhoto,
    int disputeWindowHours = 48,
  }) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not authenticated');

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      String? resolutionPhotoUrl;
      if (resolutionPhoto != null) {
        resolutionPhotoUrl = await _uploadPhoto(
          'houses/$houseId/issues/$issueId/resolution.jpg',
          resolutionPhoto,
        );
      }

      final now = Timestamp.now();
      final autoCloseAt = Timestamp.fromMillisecondsSinceEpoch(
        now.millisecondsSinceEpoch + (disputeWindowHours * 60 * 60 * 1000),
      );

      await _issuesCol(houseId).doc(issueId).update({
        'resolvedBy': uid,
        'resolvedAt': now,
        'resolutionNote': note,
        'resolutionPhotoUrl': resolutionPhotoUrl,
        'status': 'resolved',
        'autoCloseAt': autoCloseAt,
      });
    });
  }

  Future<void> dispute({
    required String houseId,
    required String issueId,
    required String reason,
    required String resolvedByUid,
  }) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not authenticated');

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _issuesCol(houseId).doc(issueId).update({
        'disputedBy': uid,
        'disputeAgainst': resolvedByUid,
        'disputeReason': reason,
        'status': 'disputed',
      });
    });
  }

  Future<void> react({
    required String houseId,
    required String issueId,
    required String emoji,
  }) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not authenticated');

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final doc = await _issuesCol(houseId).doc(issueId).get();
      final data = doc.data();
      final reactions = (data?['reactions'] as Map<String, dynamic>?) ?? {};

      if (reactions[uid] == emoji) {
        // Toggle off — remove the reaction
        await _issuesCol(houseId)
            .doc(issueId)
            .update({'reactions.$uid': FieldValue.delete()});
      } else {
        // Set the new reaction (replaces any existing one)
        await _issuesCol(houseId)
            .doc(issueId)
            .update({'reactions.$uid': emoji});
      }
    });
  }
}
