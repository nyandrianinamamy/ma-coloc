import 'package:flutter_test/flutter_test.dart';
import 'package:macoloc/src/providers/activity_provider.dart';

void main() {
  group('ActivityItem', () {
    test('mergeActivityFeed sorts by timestamp descending', () {
      final items = [
        ActivityItem(
          type: 'created',
          userName: 'Alice',
          detail: 'Dish mountain in sink',
          timestamp: DateTime(2026, 4, 1, 10, 0),
          issueId: 'i1',
        ),
        ActivityItem(
          type: 'badgeEarned',
          userName: 'Bob',
          detail: 'first_issue',
          timestamp: DateTime(2026, 4, 1, 11, 0),
        ),
        ActivityItem(
          type: 'resolved',
          userName: 'Alice',
          detail: 'Out of oat milk!',
          timestamp: DateTime(2026, 4, 1, 9, 0),
          issueId: 'i2',
          points: 5,
        ),
      ];

      items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      expect(items[0].type, 'badgeEarned');
      expect(items[1].type, 'created');
      expect(items[2].type, 'resolved');
    });
  });

  group('momentumText', () {
    test('0 issues returns encouraging message', () {
      expect(momentumText(0), "No issues resolved yet — get started!");
    });

    test('1-4 issues returns keep it up message', () {
      expect(momentumText(3), contains('3'));
      expect(momentumText(3), contains('keep it up'));
    });

    test('5+ issues returns house on fire message', () {
      expect(momentumText(7), contains('7'));
      expect(momentumText(7), contains('House on fire'));
    });
  });
}
