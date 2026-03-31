import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macoloc/src/models/activity_event.dart';

void main() {
  group('ActivityEvent', () {
    test('fromJson creates valid event', () {
      final ts = Timestamp.now();
      final event = ActivityEvent(
        id: 'a1',
        type: ActivityEventType.badgeEarned,
        uid: 'u1',
        displayName: 'Alice',
        detail: 'first_issue',
        createdAt: ts,
      );

      expect(event.type, ActivityEventType.badgeEarned);
      expect(event.uid, 'u1');
      expect(event.detail, 'first_issue');
    });

    test('ActivityEventType has all expected values', () {
      expect(ActivityEventType.values, containsAll([
        ActivityEventType.badgeEarned,
        ActivityEventType.streakMilestone,
        ActivityEventType.deepCleanDone,
      ]));
      expect(ActivityEventType.values.length, 3);
    });
  });
}
