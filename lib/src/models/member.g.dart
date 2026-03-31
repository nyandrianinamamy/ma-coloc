// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MemberStatsImpl _$$MemberStatsImplFromJson(Map<String, dynamic> json) =>
    _$MemberStatsImpl(
      totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
      issuesCreated: (json['issuesCreated'] as num?)?.toInt() ?? 0,
      issuesResolved: (json['issuesResolved'] as num?)?.toInt() ?? 0,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
      badges:
          (json['badges'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      lastRandomAssignMonth: json['lastRandomAssignMonth'] as String?,
      deepCleanRoomsCompleted:
          (json['deepCleanRoomsCompleted'] as num?)?.toInt() ?? 0,
      lastStreakDate: json['lastStreakDate'] as String?,
    );

Map<String, dynamic> _$$MemberStatsImplToJson(_$MemberStatsImpl instance) =>
    <String, dynamic>{
      'totalPoints': instance.totalPoints,
      'issuesCreated': instance.issuesCreated,
      'issuesResolved': instance.issuesResolved,
      'currentStreak': instance.currentStreak,
      'longestStreak': instance.longestStreak,
      'badges': instance.badges,
      'lastRandomAssignMonth': instance.lastRandomAssignMonth,
      'deepCleanRoomsCompleted': instance.deepCleanRoomsCompleted,
      'lastStreakDate': instance.lastStreakDate,
    };

_$MemberImpl _$$MemberImplFromJson(Map<String, dynamic> json) => _$MemberImpl(
  uid: json['uid'] as String,
  displayName: json['displayName'] as String,
  avatarUrl: json['avatarUrl'] as String?,
  joinedAt: const TimestampConverter().fromJson(json['joinedAt'] as Timestamp),
  role:
      $enumDecodeNullable(_$MemberRoleEnumMap, json['role']) ??
      MemberRole.member,
  presence:
      $enumDecodeNullable(_$PresenceEnumMap, json['presence']) ?? Presence.away,
  presenceUpdatedAt: const TimestampConverter().fromJson(
    json['presenceUpdatedAt'] as Timestamp,
  ),
  stats: json['stats'] == null
      ? const MemberStats()
      : MemberStats.fromJson(json['stats'] as Map<String, dynamic>),
  fcmToken: json['fcmToken'] as String?,
  notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
);

Map<String, dynamic> _$$MemberImplToJson(_$MemberImpl instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'displayName': instance.displayName,
      'avatarUrl': instance.avatarUrl,
      'joinedAt': const TimestampConverter().toJson(instance.joinedAt),
      'role': _$MemberRoleEnumMap[instance.role]!,
      'presence': _$PresenceEnumMap[instance.presence]!,
      'presenceUpdatedAt': const TimestampConverter().toJson(
        instance.presenceUpdatedAt,
      ),
      'stats': instance.stats.toJson(),
      'fcmToken': instance.fcmToken,
      'notificationsEnabled': instance.notificationsEnabled,
    };

const _$MemberRoleEnumMap = {
  MemberRole.admin: 'admin',
  MemberRole.member: 'member',
};

const _$PresenceEnumMap = {Presence.home: 'home', Presence.away: 'away'};
