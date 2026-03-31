import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'house.dart' show TimestampConverter;

part 'deep_clean.freezed.dart';
part 'deep_clean.g.dart';

enum DeepCleanStatus {
  volunteering,
  assigned,
  @JsonValue('in_progress')
  inProgress,
  completed,
}

@freezed
class VolunteerIntent with _$VolunteerIntent {
  const factory VolunteerIntent({
    required String uid,
    @TimestampConverter() required Timestamp volunteeredAt,
  }) = _VolunteerIntent;

  factory VolunteerIntent.fromJson(Map<String, dynamic> json) =>
      _$VolunteerIntentFromJson(json);
}

@freezed
class RoomAssignment with _$RoomAssignment {
  const factory RoomAssignment({
    String? uid,
    @Default(false) bool fromVolunteer,
    @Default(false) bool completed,
  }) = _RoomAssignment;

  factory RoomAssignment.fromJson(Map<String, dynamic> json) =>
      _$RoomAssignmentFromJson(json);
}

@freezed
class DeepClean with _$DeepClean {
  @JsonSerializable(explicitToJson: true)
  const factory DeepClean({
    required String id,
    required String month,
    required DeepCleanStatus status,
    @TimestampConverter() required Timestamp volunteerDeadline,
    @TimestampConverter() required Timestamp createdAt,
    required Map<String, List<VolunteerIntent>> volunteerIntents,
    required Map<String, RoomAssignment> assignments,
  }) = _DeepClean;

  factory DeepClean.fromJson(Map<String, dynamic> json) =>
      _$DeepCleanFromJson(json);

  factory DeepClean.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return DeepClean.fromJson({...data, 'id': doc.id});
  }
}
