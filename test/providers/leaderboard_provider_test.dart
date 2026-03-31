import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macoloc/src/models/issue.dart';
import 'package:macoloc/src/models/member.dart';
import 'package:macoloc/src/providers/leaderboard_provider.dart';

void main() {
  group('LeaderboardEntry', () {
    test('sorts by periodPoints descending', () {
      final entries = [
        LeaderboardEntry(uid: 'a', displayName: 'A', periodPoints: 10, stats: const MemberStats()),
        LeaderboardEntry(uid: 'b', displayName: 'B', periodPoints: 30, stats: const MemberStats()),
        LeaderboardEntry(uid: 'c', displayName: 'C', periodPoints: 20, stats: const MemberStats()),
      ];
      entries.sort((a, b) => b.periodPoints.compareTo(a.periodPoints));
      expect(entries.map((e) => e.uid), ['b', 'c', 'a']);
    });
  });

  group('computeLeaderboard', () {
    final now = DateTime(2026, 3, 31, 12, 0); // Tuesday

    final members = [
      Member(
        uid: 'u1',
        displayName: 'Alice',
        joinedAt: Timestamp.now(),
        presenceUpdatedAt: Timestamp.now(),
        stats: const MemberStats(totalPoints: 100),
      ),
      Member(
        uid: 'u2',
        displayName: 'Bob',
        joinedAt: Timestamp.now(),
        presenceUpdatedAt: Timestamp.now(),
        stats: const MemberStats(totalPoints: 50),
      ),
    ];

    final issues = [
      _makeClosedIssue('i1', 'u1', 5, DateTime(2026, 3, 30, 10, 0)),
      _makeClosedIssue('i2', 'u1', 10, DateTime(2026, 3, 31, 8, 0)),
      _makeClosedIssue('i3', 'u2', 3, DateTime(2026, 3, 31, 9, 0)),
      _makeClosedIssue('i4', 'u1', 5, DateTime(2026, 3, 22, 10, 0)),
    ];

    test('weekly period sums only current ISO week', () {
      final result = computeLeaderboard(
        members: members,
        closedIssues: issues,
        isWeekly: true,
        now: now,
      );
      expect(result[0].uid, 'u1');
      expect(result[0].periodPoints, 15);
      expect(result[1].uid, 'u2');
      expect(result[1].periodPoints, 3);
    });

    test('monthly period sums current calendar month', () {
      final result = computeLeaderboard(
        members: members,
        closedIssues: issues,
        isWeekly: false,
        now: now,
      );
      expect(result[0].uid, 'u1');
      expect(result[0].periodPoints, 20);
      expect(result[1].uid, 'u2');
      expect(result[1].periodPoints, 3);
    });

    test('members with no closed issues get 0 periodPoints', () {
      final result = computeLeaderboard(
        members: members,
        closedIssues: [],
        isWeekly: true,
        now: now,
      );
      expect(result[0].periodPoints, 0);
      expect(result[1].periodPoints, 0);
    });
  });
}

Issue _makeClosedIssue(String id, String resolvedBy, int points, DateTime closedAt) {
  return Issue(
    id: id,
    type: IssueType.chore,
    createdBy: 'someone',
    createdAt: Timestamp.fromDate(closedAt.subtract(const Duration(days: 1))),
    status: IssueStatus.closed,
    resolvedBy: resolvedBy,
    autoCloseAt: Timestamp.fromDate(closedAt),
    points: points,
  );
}
