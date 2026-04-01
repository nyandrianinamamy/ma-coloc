import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'house.dart' show TimestampConverter;
import 'issue.dart' show NullableTimestampConverter;

part 'member.freezed.dart';
part 'member.g.dart';

enum MemberRole { admin, member }

enum Presence { home, away }

@freezed
class MemberStats with _$MemberStats {
  const factory MemberStats({
    @Default(0) int totalPoints,
    @Default(0) int issuesCreated,
    @Default(0) int issuesResolved,
    @Default(0) int currentStreak,
    @Default(0) int longestStreak,
    @Default([]) List<String> badges,
    String? lastRandomAssignMonth,
    @Default(0) int deepCleanRoomsCompleted,
    String? lastStreakDate,
  }) = _MemberStats;

  factory MemberStats.fromJson(Map<String, dynamic> json) =>
      _$MemberStatsFromJson(json);
}

@freezed
class Member with _$Member {
  @JsonSerializable(explicitToJson: true)
  const factory Member({
    required String uid,
    required String displayName,
    String? avatarUrl,
    @TimestampConverter() required Timestamp joinedAt,
    @Default(MemberRole.member) MemberRole role,
    @Default(Presence.away) Presence presence,
    @NullableTimestampConverter() Timestamp? presenceUpdatedAt,
    @Default(MemberStats()) MemberStats stats,
    String? fcmToken,
    @Default(true) bool notificationsEnabled,
  }) = _Member;

  factory Member.fromJson(Map<String, dynamic> json) =>
      _$MemberFromJson(json);

  factory Member.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Member.fromJson({...data, 'uid': doc.id});
  }
}
