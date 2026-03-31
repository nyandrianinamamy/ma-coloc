import 'package:flutter/material.dart';
import 'member.dart';

class BadgeDefinition {
  const BadgeDefinition({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.isUnlocked,
  });

  final String id;
  final String name;
  final IconData icon;
  final String description;
  final bool Function(MemberStats stats) isUnlocked;
}

const badgeCatalog = <String, BadgeDefinition>{
  'first_issue': BadgeDefinition(
    id: 'first_issue',
    name: 'First Issue',
    icon: Icons.star_rounded,
    description: 'Resolve your first issue',
    isUnlocked: _firstIssue,
  ),
  'ten_resolved': BadgeDefinition(
    id: 'ten_resolved',
    name: 'Problem Solver',
    icon: Icons.build_rounded,
    description: 'Resolve 10 issues',
    isUnlocked: _tenResolved,
  ),
  'fifty_resolved': BadgeDefinition(
    id: 'fifty_resolved',
    name: 'Veteran',
    icon: Icons.shield_rounded,
    description: 'Resolve 50 issues',
    isUnlocked: _fiftyResolved,
  ),
  'streak_7': BadgeDefinition(
    id: 'streak_7',
    name: 'On Fire',
    icon: Icons.local_fire_department_rounded,
    description: 'Reach a 7-day streak',
    isUnlocked: _streak7,
  ),
  'streak_30': BadgeDefinition(
    id: 'streak_30',
    name: 'Unstoppable',
    icon: Icons.rocket_launch_rounded,
    description: 'Reach a 30-day streak',
    isUnlocked: _streak30,
  ),
  'deep_clean_1': BadgeDefinition(
    id: 'deep_clean_1',
    name: 'Clean Freak',
    icon: Icons.auto_awesome_rounded,
    description: 'Complete your first deep clean room',
    isUnlocked: _deepClean1,
  ),
  'deep_clean_10': BadgeDefinition(
    id: 'deep_clean_10',
    name: 'Cleaning Machine',
    icon: Icons.cleaning_services_rounded,
    description: 'Complete 10 deep clean rooms',
    isUnlocked: _deepClean10,
  ),
  'points_100': BadgeDefinition(
    id: 'points_100',
    name: 'Century',
    icon: Icons.emoji_events_rounded,
    description: 'Earn 100 total points',
    isUnlocked: _points100,
  ),
};

bool _firstIssue(MemberStats s) => s.issuesResolved >= 1;
bool _tenResolved(MemberStats s) => s.issuesResolved >= 10;
bool _fiftyResolved(MemberStats s) => s.issuesResolved >= 50;
bool _streak7(MemberStats s) => s.longestStreak >= 7;
bool _streak30(MemberStats s) => s.longestStreak >= 30;
bool _deepClean1(MemberStats s) => s.deepCleanRoomsCompleted >= 1;
bool _deepClean10(MemberStats s) => s.deepCleanRoomsCompleted >= 10;
bool _points100(MemberStats s) => s.totalPoints >= 100;

List<String> evaluateNewBadges(MemberStats stats, List<String> existing) {
  return badgeCatalog.entries
      .where((e) => e.value.isUnlocked(stats) && !existing.contains(e.key))
      .map((e) => e.key)
      .toList();
}
