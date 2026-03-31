import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity_event.dart';
import '../models/issue.dart';
import 'house_provider.dart';

// ---------------------------------------------------------------------------
// Unified activity item (merges issue events + activity subcollection)
// ---------------------------------------------------------------------------

class ActivityItem {
  const ActivityItem({
    required this.type,
    required this.userName,
    required this.detail,
    required this.timestamp,
    this.issueId,
    this.points,
  });

  final String type;
  final String userName;
  final String detail;
  final DateTime timestamp;
  final String? issueId;
  final int? points;
}

// ---------------------------------------------------------------------------
// Momentum text
// ---------------------------------------------------------------------------

String momentumText(int resolvedCount) {
  if (resolvedCount == 0) {
    return "No issues resolved yet — get started!";
  } else if (resolvedCount < 5) {
    return "Your house resolved $resolvedCount issues this week — keep it up!";
  } else {
    return "House on fire! Your house resolved $resolvedCount issues this week";
  }
}

// ---------------------------------------------------------------------------
// Activity subcollection stream
// ---------------------------------------------------------------------------

final activityStreamProvider =
    StreamProvider.family<List<ActivityEvent>, String>((ref, houseId) {
  final db = ref.watch(firestoreProvider);
  return db
      .collection('houses/$houseId/activity')
      .orderBy('createdAt', descending: true)
      .limit(20)
      .snapshots()
      .map((snap) => snap.docs.map(ActivityEvent.fromFirestore).toList());
});

// ---------------------------------------------------------------------------
// Merged activity feed (issue events + activity subcollection)
// ---------------------------------------------------------------------------

final activityFeedProvider =
    Provider.family<AsyncValue<List<ActivityItem>>, String>((ref, houseId) {
  final activityAsync = ref.watch(activityStreamProvider(houseId));
  final recentIssuesAsync = ref.watch(_recentIssuesProvider(houseId));

  return activityAsync.when(
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
    data: (activityEvents) => recentIssuesAsync.when(
      loading: () => const AsyncLoading(),
      error: (e, st) => AsyncError(e, st),
      data: (issues) {
        final items = <ActivityItem>[];

        for (final issue in issues) {
          items.add(ActivityItem(
            type: 'created',
            userName: issue.createdBy,
            detail: issue.title ?? 'Untitled',
            timestamp: issue.createdAt.toDate(),
            issueId: issue.id,
          ));

          if (issue.resolvedBy != null && issue.resolvedAt != null) {
            items.add(ActivityItem(
              type: 'resolved',
              userName: issue.resolvedBy!,
              detail: issue.title ?? 'Untitled',
              timestamp: issue.resolvedAt!.toDate(),
              issueId: issue.id,
              points: issue.points,
            ));
          }
        }

        for (final event in activityEvents) {
          items.add(ActivityItem(
            type: event.type.name,
            userName: event.displayName,
            detail: event.detail,
            timestamp: event.createdAt.toDate(),
          ));
        }

        items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return AsyncData(items.take(30).toList());
      },
    ),
  );
});

final _recentIssuesProvider =
    StreamProvider.family<List<Issue>, String>((ref, houseId) {
  final db = ref.watch(firestoreProvider);
  return db
      .collection('houses/$houseId/issues')
      .orderBy('createdAt', descending: true)
      .limit(20)
      .snapshots()
      .map((snap) => snap.docs.map(Issue.fromFirestore).toList());
});
