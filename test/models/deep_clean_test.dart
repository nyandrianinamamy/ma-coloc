import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:macoloc/src/models/deep_clean.dart';

void main() {
  group('VolunteerIntent', () {
    test('serializes to and from JSON', () {
      final intent = VolunteerIntent(
        uid: 'uid1',
        volunteeredAt: Timestamp.now(),
      );
      final json = intent.toJson();
      final restored = VolunteerIntent.fromJson(json);
      expect(restored.uid, 'uid1');
    });
  });

  group('RoomAssignment', () {
    test('creates volunteer assignment', () {
      const assignment = RoomAssignment(
        uid: 'uid1',
        fromVolunteer: true,
        completed: false,
      );
      expect(assignment.fromVolunteer, isTrue);
      expect(assignment.completed, isFalse);
    });

    test('allows null uid for unassignable rooms', () {
      const assignment = RoomAssignment(
        fromVolunteer: false,
        completed: false,
      );
      expect(assignment.uid, isNull);
    });
  });

  group('DeepClean', () {
    test('creates in volunteering status', () {
      final deepClean = DeepClean(
        id: 'dc1',
        month: '2026-04',
        status: DeepCleanStatus.volunteering,
        volunteerDeadline: Timestamp.now(),
        createdAt: Timestamp.now(),
        volunteerIntents: const {},
        assignments: const {},
      );
      expect(deepClean.status, DeepCleanStatus.volunteering);
      expect(deepClean.volunteerIntents, isEmpty);
      expect(deepClean.assignments, isEmpty);
    });

    test('volunteer intents hold multiple entries per room', () {
      final now = Timestamp.now();
      final deepClean = DeepClean(
        id: 'dc2',
        month: '2026-04',
        status: DeepCleanStatus.volunteering,
        volunteerDeadline: now,
        createdAt: now,
        volunteerIntents: {
          'Kitchen': [
            VolunteerIntent(uid: 'uid1', volunteeredAt: now),
            VolunteerIntent(uid: 'uid2', volunteeredAt: now),
          ],
        },
        assignments: const {},
      );
      expect(deepClean.volunteerIntents['Kitchen'], hasLength(2));
    });

    test('serializes full deep clean with assignments', () {
      final now = Timestamp.now();
      final deepClean = DeepClean(
        id: 'dc3',
        month: '2026-04',
        status: DeepCleanStatus.assigned,
        volunteerDeadline: now,
        createdAt: now,
        volunteerIntents: {
          'Kitchen': [VolunteerIntent(uid: 'uid1', volunteeredAt: now)],
        },
        assignments: const {
          'Kitchen': RoomAssignment(uid: 'uid1', fromVolunteer: true, completed: false),
          'Bathroom': RoomAssignment(uid: 'uid2', fromVolunteer: false, completed: false),
        },
      );
      final json = deepClean.toJson();
      final restored = DeepClean.fromJson(json);
      expect(restored.assignments['Kitchen']?.fromVolunteer, isTrue);
      expect(restored.assignments['Bathroom']?.uid, 'uid2');
    });
  });
}
