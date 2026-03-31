import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:macoloc/src/models/member.dart';

void main() {
  group('MemberStats', () {
    test('creates with zero defaults', () {
      const stats = MemberStats();
      expect(stats.totalPoints, 0);
      expect(stats.issuesCreated, 0);
      expect(stats.issuesResolved, 0);
      expect(stats.currentStreak, 0);
      expect(stats.longestStreak, 0);
      expect(stats.badges, isEmpty);
      expect(stats.lastRandomAssignMonth, isNull);
    });
  });

  group('Member', () {
    test('creates with required fields', () {
      final member = Member(
        uid: 'uid1',
        displayName: 'Mamy',
        joinedAt: Timestamp.now(),
        presence: Presence.away,
        presenceUpdatedAt: Timestamp.now(),
      );
      expect(member.displayName, 'Mamy');
      expect(member.role, MemberRole.member);
      expect(member.presence, Presence.away);
      expect(member.avatarUrl, isNull);
    });

    test('admin role serializes correctly', () {
      final member = Member(
        uid: 'uid1',
        displayName: 'Admin',
        joinedAt: Timestamp.now(),
        role: MemberRole.admin,
        presence: Presence.home,
        presenceUpdatedAt: Timestamp.now(),
      );
      final json = member.toJson();
      final restored = Member.fromJson(json);
      expect(restored.role, MemberRole.admin);
      expect(restored.presence, Presence.home);
    });

    test('stats roundtrip through JSON', () {
      final member = Member(
        uid: 'uid1',
        displayName: 'Test',
        joinedAt: Timestamp.now(),
        presence: Presence.away,
        presenceUpdatedAt: Timestamp.now(),
        stats: const MemberStats(
          totalPoints: 42,
          issuesResolved: 10,
          badges: ['first-issue', '10-resolved'],
          lastRandomAssignMonth: '2026-02',
        ),
      );
      final json = member.toJson();
      final restored = Member.fromJson(json);
      expect(restored.stats.totalPoints, 42);
      expect(restored.stats.badges, contains('10-resolved'));
      expect(restored.stats.lastRandomAssignMonth, '2026-02');
    });
  });
}
