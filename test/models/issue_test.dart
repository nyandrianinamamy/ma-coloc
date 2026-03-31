import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:macoloc/src/models/issue.dart';

void main() {
  group('Issue', () {
    test('creates minimal issue (photo-only, anonymous)', () {
      final issue = Issue(
        id: 'issue1',
        type: IssueType.chore,
        createdBy: 'uid1',
        anonymous: true,
        createdAt: Timestamp.now(),
        status: IssueStatus.open,
        photoUrl: 'https://example.com/photo.jpg',
        points: 5,
      );
      expect(issue.title, isNull);
      expect(issue.description, isNull);
      expect(issue.anonymous, isTrue);
      expect(issue.assignedTo, isNull);
      expect(issue.resolvedBy, isNull);
      expect(issue.reactions, isEmpty);
      expect(issue.tags, isEmpty);
    });

    test('points computed by type', () {
      expect(Issue.pointsForType(IssueType.chore), 5);
      expect(Issue.pointsForType(IssueType.repair), 10);
      expect(Issue.pointsForType(IssueType.grocery), 3);
      expect(Issue.pointsForType(IssueType.other), 5);
    });

    test('issue with full resolution serializes correctly', () {
      final now = Timestamp.now();
      final issue = Issue(
        id: 'issue2',
        type: IssueType.repair,
        title: 'Broken faucet',
        description: 'Kitchen sink leaking',
        photoUrl: 'https://example.com/faucet.jpg',
        createdBy: 'uid1',
        anonymous: false,
        createdAt: now,
        status: IssueStatus.resolved,
        assignedTo: 'uid2',
        assignedAt: now,
        resolvedBy: 'uid2',
        resolvedAt: now,
        resolutionPhotoUrl: 'https://example.com/fixed.jpg',
        resolutionNote: 'Replaced washer',
        autoCloseAt: now,
        reactions: const {'uid3': 'thumbsUp', 'uid4': 'party'},
        tags: const ['urgent', 'kitchen'],
        points: 10,
      );
      final json = issue.toJson();
      final restored = Issue.fromJson(json);
      expect(restored.resolvedBy, 'uid2');
      expect(restored.reactions, hasLength(2));
      expect(restored.tags, contains('kitchen'));
      expect(restored.points, 10);
    });

    test('dispute fields serialize correctly', () {
      final issue = Issue(
        id: 'issue3',
        type: IssueType.chore,
        createdBy: 'uid1',
        anonymous: false,
        createdAt: Timestamp.now(),
        status: IssueStatus.disputed,
        disputedBy: 'uid3',
        disputeAgainst: 'uid2',
        disputeReason: 'Not actually clean',
        points: 5,
      );
      final json = issue.toJson();
      final restored = Issue.fromJson(json);
      expect(restored.status, IssueStatus.disputed);
      expect(restored.disputedBy, 'uid3');
      expect(restored.disputeAgainst, 'uid2');
    });
  });
}
