// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'house.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HouseImpl _$$HouseImplFromJson(Map<String, dynamic> json) => _$HouseImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  createdBy: json['createdBy'] as String,
  createdAt: const TimestampConverter().fromJson(
    json['createdAt'] as Timestamp,
  ),
  inviteCode: json['inviteCode'] as String,
  members: (json['members'] as List<dynamic>).map((e) => e as String).toList(),
  rooms: (json['rooms'] as List<dynamic>).map((e) => e as String).toList(),
  timezone: json['timezone'] as String,
  lastResetDate: json['lastResetDate'] as String?,
  lastDeepCleanMonth: json['lastDeepCleanMonth'] as String?,
  settings: json['settings'] == null
      ? const HouseSettings()
      : HouseSettings.fromJson(json['settings'] as Map<String, dynamic>),
  isDemo: json['isDemo'] as bool? ?? false,
);

Map<String, dynamic> _$$HouseImplToJson(_$HouseImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'createdBy': instance.createdBy,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'inviteCode': instance.inviteCode,
      'members': instance.members,
      'rooms': instance.rooms,
      'timezone': instance.timezone,
      'lastResetDate': instance.lastResetDate,
      'lastDeepCleanMonth': instance.lastDeepCleanMonth,
      'settings': instance.settings.toJson(),
      'isDemo': instance.isDemo,
    };
