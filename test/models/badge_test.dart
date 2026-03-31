import 'package:flutter_test/flutter_test.dart';
import 'package:macoloc/src/models/badge.dart';
import 'package:macoloc/src/models/member.dart';

void main() {
  group('BadgeDefinition', () {
    test('catalog contains all 8 predefined badges', () {
      expect(badgeCatalog.length, 8);
      expect(badgeCatalog.keys, containsAll([
        'first_issue',
        'ten_resolved',
        'fifty_resolved',
        'streak_7',
        'streak_30',
        'deep_clean_1',
        'deep_clean_10',
        'points_100',
      ]));
    });

    test('first_issue unlocks at 1 resolved', () {
      final badge = badgeCatalog['first_issue']!;
      expect(badge.isUnlocked(const MemberStats(issuesResolved: 0)), false);
      expect(badge.isUnlocked(const MemberStats(issuesResolved: 1)), true);
      expect(badge.isUnlocked(const MemberStats(issuesResolved: 5)), true);
    });

    test('streak_7 unlocks at longestStreak 7', () {
      final badge = badgeCatalog['streak_7']!;
      expect(badge.isUnlocked(const MemberStats(longestStreak: 6)), false);
      expect(badge.isUnlocked(const MemberStats(longestStreak: 7)), true);
    });

    test('deep_clean_1 unlocks at 1 room completed', () {
      final badge = badgeCatalog['deep_clean_1']!;
      expect(badge.isUnlocked(const MemberStats(deepCleanRoomsCompleted: 0)), false);
      expect(badge.isUnlocked(const MemberStats(deepCleanRoomsCompleted: 1)), true);
    });

    test('points_100 unlocks at 100 total points', () {
      final badge = badgeCatalog['points_100']!;
      expect(badge.isUnlocked(const MemberStats(totalPoints: 99)), false);
      expect(badge.isUnlocked(const MemberStats(totalPoints: 100)), true);
    });

    test('evaluateNewBadges returns only newly earned badges', () {
      final stats = const MemberStats(
        issuesResolved: 1,
        totalPoints: 50,
        longestStreak: 3,
      );
      final existing = <String>[];
      final newBadges = evaluateNewBadges(stats, existing);
      expect(newBadges, contains('first_issue'));
      expect(newBadges, isNot(contains('ten_resolved')));

      final newBadges2 = evaluateNewBadges(stats, ['first_issue']);
      expect(newBadges2, isNot(contains('first_issue')));
    });
  });
}
