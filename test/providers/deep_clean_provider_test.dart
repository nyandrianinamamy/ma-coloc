import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:macoloc/src/models/deep_clean.dart';

void main() {
  group('DeepCleanStatus enum', () {
    test('has all expected values', () {
      expect(DeepCleanStatus.values, containsAll([
        DeepCleanStatus.volunteering,
        DeepCleanStatus.assigned,
        DeepCleanStatus.inProgress,
        DeepCleanStatus.completed,
      ]));
      expect(DeepCleanStatus.values.length, 4);
    });
  });

  group('currentMonth format', () {
    test('produces yyyy-MM format', () {
      final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
      expect(currentMonth, matches(RegExp(r'^\d{4}-\d{2}$')));
    });
  });

  group('RoomAssignment', () {
    test('default values', () {
      const assignment = RoomAssignment();
      expect(assignment.uid, isNull);
      expect(assignment.fromVolunteer, false);
      expect(assignment.completed, false);
    });

    test('fromJson with uid', () {
      final json = {'uid': 'user1', 'fromVolunteer': false, 'completed': true};
      final assignment = RoomAssignment.fromJson(json);
      expect(assignment.uid, 'user1');
      expect(assignment.completed, true);
    });
  });
}
