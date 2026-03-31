import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

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
  return issues.where((i) {
    if (i.title == null) return false;
    return i.title!.toLowerCase().contains(lower);
  }).toList();
}

// ---------------------------------------------------------------------------
// Stream providers
// ---------------------------------------------------------------------------

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

final issueActionsProvider =
    NotifierProvider<IssueActions, AsyncValue<void>>(IssueActions.new);

class IssueActions extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  FirebaseFirestore get _db => ref.read(firestoreProvider);
  FirebaseStorage get _storage => ref.read(firebaseStorageProvider);
  String get _uid => ref.read(authStateProvider).valueOrNull!.uid;

  Future<String?> _uploadPhoto(String path, XFile photo) async {
    final ref = _storage.ref(path);
    await ref.putFile(File(photo.path));
    return ref.getDownloadURL();
  }

  Future<void> create({
    required String houseId,
    required IssueType type,
    String? title,
    String? description,
    bool anonymous = false,
    XFile? photo,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final issueId = const Uuid().v4();

      String? photoUrl;
      if (photo != null) {
        photoUrl = await _uploadPhoto(
          'houses/$houseId/issues/$issueId/photo.jpg',
          photo,
        );
      }

      final issue = Issue(
        id: issueId,
        type: type,
        title: title,
        description: description,
        photoUrl: photoUrl,
        createdBy: _uid,
        anonymous: anonymous,
        createdAt: Timestamp.now(),
        points: Issue.pointsForType(type),
      );

      await _db
          .collection('houses/$houseId/issues')
          .doc(issueId)
          .set(issue.toJson());
    });
  }

  Future<void> claim({
    required String houseId,
    required String issueId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _db.collection('houses/$houseId/issues').doc(issueId).update({
        'assignedTo': _uid,
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
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      String? resolutionPhotoUrl;
      if (resolutionPhoto != null) {
        resolutionPhotoUrl = await _uploadPhoto(
          'houses/$houseId/issues/$issueId/resolution.jpg',
          resolutionPhoto,
        );
      }

      await _db.collection('houses/$houseId/issues').doc(issueId).update({
        'resolvedBy': _uid,
        'resolvedAt': FieldValue.serverTimestamp(),
        'resolutionNote': note,
        'resolutionPhotoUrl': resolutionPhotoUrl,
        'status': 'resolved',
      });
    });
  }

  Future<void> dispute({
    required String houseId,
    required String issueId,
    required String reason,
    required String resolvedByUid,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _db.collection('houses/$houseId/issues').doc(issueId).update({
        'disputedBy': _uid,
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
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final uid = _uid;
      final doc =
          await _db.collection('houses/$houseId/issues').doc(issueId).get();
      final data = doc.data();
      final reactions = (data?['reactions'] as Map<String, dynamic>?) ?? {};

      if (reactions[uid] == emoji) {
        // Toggle off — remove the reaction
        await _db
            .collection('houses/$houseId/issues')
            .doc(issueId)
            .update({'reactions.$uid': FieldValue.delete()});
      } else {
        // Set the new reaction (replaces any existing one)
        await _db
            .collection('houses/$houseId/issues')
            .doc(issueId)
            .update({'reactions.$uid': emoji});
      }
    });
  }
}
