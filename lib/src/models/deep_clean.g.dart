// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deep_clean.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VolunteerIntentImpl _$$VolunteerIntentImplFromJson(
  Map<String, dynamic> json,
) => _$VolunteerIntentImpl(
  uid: json['uid'] as String,
  volunteeredAt: const TimestampConverter().fromJson(
    json['volunteeredAt'] as Timestamp,
  ),
);

Map<String, dynamic> _$$VolunteerIntentImplToJson(
  _$VolunteerIntentImpl instance,
) => <String, dynamic>{
  'uid': instance.uid,
  'volunteeredAt': const TimestampConverter().toJson(instance.volunteeredAt),
};

_$RoomAssignmentImpl _$$RoomAssignmentImplFromJson(Map<String, dynamic> json) =>
    _$RoomAssignmentImpl(
      uid: json['uid'] as String?,
      fromVolunteer: json['fromVolunteer'] as bool? ?? false,
      completed: json['completed'] as bool? ?? false,
    );

Map<String, dynamic> _$$RoomAssignmentImplToJson(
  _$RoomAssignmentImpl instance,
) => <String, dynamic>{
  'uid': instance.uid,
  'fromVolunteer': instance.fromVolunteer,
  'completed': instance.completed,
};

_$DeepCleanImpl _$$DeepCleanImplFromJson(Map<String, dynamic> json) =>
    _$DeepCleanImpl(
      id: json['id'] as String,
      month: json['month'] as String,
      status: $enumDecode(_$DeepCleanStatusEnumMap, json['status']),
      volunteerDeadline: const TimestampConverter().fromJson(
        json['volunteerDeadline'] as Timestamp,
      ),
      createdAt: const TimestampConverter().fromJson(
        json['createdAt'] as Timestamp,
      ),
      volunteerIntents: (json['volunteerIntents'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
          k,
          (e as List<dynamic>)
              .map((e) => VolunteerIntent.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      ),
      assignments: (json['assignments'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, RoomAssignment.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$$DeepCleanImplToJson(
  _$DeepCleanImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'month': instance.month,
  'status': _$DeepCleanStatusEnumMap[instance.status]!,
  'volunteerDeadline': const TimestampConverter().toJson(
    instance.volunteerDeadline,
  ),
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'volunteerIntents': instance.volunteerIntents.map(
    (k, e) => MapEntry(k, e.map((e) => e.toJson()).toList()),
  ),
  'assignments': instance.assignments.map((k, e) => MapEntry(k, e.toJson())),
};

const _$DeepCleanStatusEnumMap = {
  DeepCleanStatus.volunteering: 'volunteering',
  DeepCleanStatus.assigned: 'assigned',
  DeepCleanStatus.inProgress: 'in_progress',
  DeepCleanStatus.completed: 'completed',
};
