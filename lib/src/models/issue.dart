import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'house.dart' show TimestampConverter;

part 'issue.freezed.dart';
part 'issue.g.dart';

enum IssueType {
  chore,
  grocery,
  repair,
  other,
}

enum IssueStatus {
  open,
  @JsonValue('in_progress')
  inProgress,
  resolved,
  disputed,
  closed,
}

class NullableTimestampConverter
    implements JsonConverter<Timestamp?, Timestamp?> {
  const NullableTimestampConverter();

  @override
  Timestamp? fromJson(Timestamp? json) => json;

  @override
  Timestamp? toJson(Timestamp? object) => object;
}

@freezed
class Issue with _$Issue {
  const Issue._();

  const factory Issue({
    required String id,
    required IssueType type,
    String? title,
    String? description,
    String? photoUrl,
    required String createdBy,
    @Default(false) bool anonymous,
    @TimestampConverter() required Timestamp createdAt,
    // Assignment
    String? assignedTo,
    @NullableTimestampConverter() Timestamp? assignedAt,
    // Resolution
    @Default(IssueStatus.open) IssueStatus status,
    String? resolvedBy,
    @NullableTimestampConverter() Timestamp? resolvedAt,
    String? resolutionPhotoUrl,
    String? resolutionNote,
    // Dispute
    String? disputedBy,
    String? disputeAgainst,
    String? disputeReason,
    @Default({}) Map<String, String> reactions,
    @NullableTimestampConverter() Timestamp? autoCloseAt,
    @NullableTimestampConverter() Timestamp? closedAt,
    // Categorization
    @Default([]) List<String> tags,
    required int points,
    // Archive
    @Default(false) bool archived,
  }) = _Issue;

  factory Issue.fromJson(Map<String, dynamic> json) => _$IssueFromJson(json);

  factory Issue.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Issue.fromJson({...data, 'id': doc.id});
  }

  static int pointsForType(IssueType type) {
    switch (type) {
      case IssueType.chore:
        return 5;
      case IssueType.repair:
        return 10;
      case IssueType.grocery:
        return 3;
      case IssueType.other:
        return 5;
    }
  }
}
