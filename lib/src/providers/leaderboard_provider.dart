import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/issue.dart';
import '../models/member.dart';
import 'house_provider.dart';
import 'member_provider.dart';

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.uid,
    required this.displayName,
    this.avatarUrl,
    required this.periodPoints,
    required this.stats,
  });

  final String uid;
  final String displayName;
  final String? avatarUrl;
  final int periodPoints;
  final MemberStats stats;
}

List<LeaderboardEntry> computeLeaderboard({
  required List<Member> members,
  required List<Issue> closedIssues,
  required bool isWeekly,
  required DateTime now,
}) {
  final DateTime periodStart;
  if (isWeekly) {
    periodStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
  } else {
    periodStart = DateTime(now.year, now.month, 1);
  }

  final pointsByUid = <String, int>{};
  for (final issue in closedIssues) {
    if (issue.resolvedBy == null) continue;
    final closedAt = issue.closedAt?.toDate() ?? issue.autoCloseAt?.toDate() ?? issue.createdAt.toDate();

    if (!closedAt.isBefore(periodStart) && !closedAt.isAfter(now)) {
      pointsByUid[issue.resolvedBy!] =
          (pointsByUid[issue.resolvedBy!] ?? 0) + issue.points;
    }
  }

  final entries = members.map((m) {
    return LeaderboardEntry(
      uid: m.uid,
      displayName: m.displayName,
      avatarUrl: m.avatarUrl,
      periodPoints: pointsByUid[m.uid] ?? 0,
      stats: m.stats,
    );
  }).toList();

  entries.sort((a, b) => b.periodPoints.compareTo(a.periodPoints));
  return entries;
}

class LeaderboardParams {
  const LeaderboardParams({required this.houseId, required this.isWeekly});

  final String houseId;
  final bool isWeekly;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaderboardParams &&
          houseId == other.houseId &&
          isWeekly == other.isWeekly;

  @override
  int get hashCode => Object.hash(houseId, isWeekly);
}

final closedIssuesStreamProvider =
    StreamProvider.family<List<Issue>, String>((ref, houseId) {
  final db = ref.watch(firestoreProvider);
  return db
      .collection('houses/$houseId/issues')
      .where('status', isEqualTo: 'closed')
      .orderBy('closedAt', descending: true)
      .limit(200)
      .snapshots()
      .map((snap) => snap.docs.map(Issue.fromFirestore).toList());
});

final leaderboardProvider =
    Provider.family<AsyncValue<List<LeaderboardEntry>>, LeaderboardParams>(
        (ref, params) {
  final membersAsync = ref.watch(membersStreamProvider(params.houseId));
  final issuesAsync = ref.watch(closedIssuesStreamProvider(params.houseId));

  return membersAsync.when(
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
    data: (members) => issuesAsync.when(
      loading: () => const AsyncLoading(),
      error: (e, st) => AsyncError(e, st),
      data: (issues) {
        final entries = computeLeaderboard(
          members: members,
          closedIssues: issues,
          isWeekly: params.isWeekly,
          now: DateTime.now(),
        );
        return AsyncData(entries);
      },
    ),
  );
});
