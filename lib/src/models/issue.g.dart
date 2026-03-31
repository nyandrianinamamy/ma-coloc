// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'issue.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$IssueImpl _$$IssueImplFromJson(Map<String, dynamic> json) => _$IssueImpl(
  id: json['id'] as String,
  type: $enumDecode(_$IssueTypeEnumMap, json['type']),
  title: json['title'] as String?,
  description: json['description'] as String?,
  photoUrl: json['photoUrl'] as String?,
  createdBy: json['createdBy'] as String,
  anonymous: json['anonymous'] as bool? ?? false,
  createdAt: const TimestampConverter().fromJson(
    json['createdAt'] as Timestamp,
  ),
  assignedTo: json['assignedTo'] as String?,
  assignedAt: const NullableTimestampConverter().fromJson(
    json['assignedAt'] as Timestamp?,
  ),
  status:
      $enumDecodeNullable(_$IssueStatusEnumMap, json['status']) ??
      IssueStatus.open,
  resolvedBy: json['resolvedBy'] as String?,
  resolvedAt: const NullableTimestampConverter().fromJson(
    json['resolvedAt'] as Timestamp?,
  ),
  resolutionPhotoUrl: json['resolutionPhotoUrl'] as String?,
  resolutionNote: json['resolutionNote'] as String?,
  disputedBy: json['disputedBy'] as String?,
  disputeAgainst: json['disputeAgainst'] as String?,
  disputeReason: json['disputeReason'] as String?,
  reactions:
      (json['reactions'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const {},
  autoCloseAt: const NullableTimestampConverter().fromJson(
    json['autoCloseAt'] as Timestamp?,
  ),
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  points: (json['points'] as num).toInt(),
);

Map<String, dynamic> _$$IssueImplToJson(
  _$IssueImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': _$IssueTypeEnumMap[instance.type]!,
  'title': instance.title,
  'description': instance.description,
  'photoUrl': instance.photoUrl,
  'createdBy': instance.createdBy,
  'anonymous': instance.anonymous,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'assignedTo': instance.assignedTo,
  'assignedAt': const NullableTimestampConverter().toJson(instance.assignedAt),
  'status': _$IssueStatusEnumMap[instance.status]!,
  'resolvedBy': instance.resolvedBy,
  'resolvedAt': const NullableTimestampConverter().toJson(instance.resolvedAt),
  'resolutionPhotoUrl': instance.resolutionPhotoUrl,
  'resolutionNote': instance.resolutionNote,
  'disputedBy': instance.disputedBy,
  'disputeAgainst': instance.disputeAgainst,
  'disputeReason': instance.disputeReason,
  'reactions': instance.reactions,
  'autoCloseAt': const NullableTimestampConverter().toJson(
    instance.autoCloseAt,
  ),
  'tags': instance.tags,
  'points': instance.points,
};

const _$IssueTypeEnumMap = {
  IssueType.chore: 'chore',
  IssueType.grocery: 'grocery',
  IssueType.repair: 'repair',
  IssueType.other: 'other',
};

const _$IssueStatusEnumMap = {
  IssueStatus.open: 'open',
  IssueStatus.inProgress: 'in_progress',
  IssueStatus.resolved: 'resolved',
  IssueStatus.disputed: 'disputed',
  IssueStatus.closed: 'closed',
};
