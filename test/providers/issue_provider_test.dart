import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macoloc/src/models/issue.dart';
import 'package:macoloc/src/providers/issue_provider.dart';

Issue _makeIssue({
  required String id,
  IssueType type = IssueType.chore,
  String? title,
}) {
  return Issue(
    id: id,
    type: type,
    title: title,
    createdBy: 'uid1',
    createdAt: Timestamp.now(),
    points: Issue.pointsForType(type),
  );
}

void main() {
  group('IssueTab enum', () {
    test('has 3 values: all, mine, open', () {
      expect(IssueTab.values, hasLength(3));
      expect(IssueTab.values, containsAll([IssueTab.all, IssueTab.mine, IssueTab.open]));
    });
  });

  group('IssueQueryParams', () {
    test('same params are equal', () {
      final a = IssueQueryParams(houseId: 'house1', tab: IssueTab.all);
      final b = IssueQueryParams(houseId: 'house1', tab: IssueTab.all);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different tab means not equal', () {
      final a = IssueQueryParams(houseId: 'house1', tab: IssueTab.all);
      final b = IssueQueryParams(houseId: 'house1', tab: IssueTab.mine);
      expect(a, isNot(equals(b)));
    });
  });

  group('filterByType', () {
    final issues = [
      _makeIssue(id: '1', type: IssueType.chore),
      _makeIssue(id: '2', type: IssueType.repair),
      _makeIssue(id: '3', type: IssueType.chore),
      _makeIssue(id: '4', type: IssueType.grocery),
    ];

    test('null filter returns all issues', () {
      expect(filterByType(issues, null), equals(issues));
    });

    test('specific type returns only matching issues', () {
      final result = filterByType(issues, IssueType.chore);
      expect(result, hasLength(2));
      expect(result.every((i) => i.type == IssueType.chore), isTrue);
    });

    test('returns empty list when no matches', () {
      final result = filterByType(issues, IssueType.other);
      expect(result, isEmpty);
    });
  });

  group('filterBySearch', () {
    final issues = [
      _makeIssue(id: '1', title: 'Broken faucet'),
      _makeIssue(id: '2', title: 'Dirty kitchen'),
      _makeIssue(id: '3', title: null),
      _makeIssue(id: '4', title: 'BROKEN window'),
    ];

    test('empty query returns all issues', () {
      expect(filterBySearch(issues, ''), equals(issues));
    });

    test('is case-insensitive', () {
      final result = filterBySearch(issues, 'broken');
      expect(result, hasLength(2));
      expect(result.map((i) => i.id), containsAll(['1', '4']));
    });

    test('excludes issues with null title', () {
      final result = filterBySearch(issues, 'kitchen');
      expect(result.any((i) => i.title == null), isFalse);
    });
  });
}
