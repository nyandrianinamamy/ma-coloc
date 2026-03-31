// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'house_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HouseSettingsImpl _$$HouseSettingsImplFromJson(Map<String, dynamic> json) =>
    _$HouseSettingsImpl(
      deepCleanDay: (json['deepCleanDay'] as num?)?.toInt() ?? 1,
      volunteerWindowHours:
          (json['volunteerWindowHours'] as num?)?.toInt() ?? 48,
      disputeWindowHours: (json['disputeWindowHours'] as num?)?.toInt() ?? 48,
    );

Map<String, dynamic> _$$HouseSettingsImplToJson(_$HouseSettingsImpl instance) =>
    <String, dynamic>{
      'deepCleanDay': instance.deepCleanDay,
      'volunteerWindowHours': instance.volunteerWindowHours,
      'disputeWindowHours': instance.disputeWindowHours,
    };
