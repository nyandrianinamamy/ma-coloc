import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../firebase_options.dart';
import '../../mock/mock_data.dart';
import '../../models/member.dart';
import '../../providers/activity_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/deep_clean_provider.dart';
import '../../providers/house_provider.dart';
import '../../providers/leaderboard_provider.dart';
import '../../providers/member_provider.dart';
import '../../providers/notification_provider.dart';
import '../../theme/app_theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Used only in placeholder/mock mode
  bool _isHome = true;

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = kDebugMode && DefaultFirebaseOptions.isPlaceholder;
    if (isPlaceholder) return _buildWithMockData(context);

    final houseIdAsync = ref.watch(currentHouseIdProvider);
    final houseId = houseIdAsync.valueOrNull;

    if (houseId == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final house = ref.watch(currentHouseProvider).valueOrNull;
    final membersAsync = ref.watch(membersStreamProvider(houseId));
    final currentUid = ref.watch(authStateProvider).valueOrNull?.uid;

    return membersAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Error: $e')),
      ),
      data: (members) {
        ref.watch(notificationSetupProvider);

        final currentMemberList =
            members.where((m) => m.uid == currentUid).toList();
        final isHome = currentMemberList.isNotEmpty &&
            currentMemberList.first.presence == Presence.home;
        final homeMembers =
            members.where((m) => m.presence == Presence.home).toList();

        // Activity feed
        final activityFeedAsync = ref.watch(activityFeedProvider(houseId));
        final liveActivities = activityFeedAsync.valueOrNull ?? [];

        // Momentum: count issues closed this ISO week
        final closedIssuesAsync =
            ref.watch(closedIssuesStreamProvider(houseId));
        final closedIssues = closedIssuesAsync.valueOrNull ?? [];
        final now = DateTime.now();
        final weekStart = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        final weeklyCount = closedIssues
            .where((i) =>
                i.closedAt != null &&
                !i.closedAt!.toDate().isBefore(weekStart))
            .length;

        // Deep clean: count unclaimed rooms
        final deepCleanAsync =
            ref.watch(currentDeepCleanProvider(houseId));
        final deepClean = deepCleanAsync.valueOrNull;
        final unclaimedCount = deepClean == null
            ? 0
            : deepClean.assignments.values
                .where((a) => a.uid == null)
                .length;

        return _buildScaffold(
          context: context,
          houseName: house?.name ?? 'My House',
          memberCount: members.length,
          isHome: isHome,
          onPresenceChanged: (value) {
            ref.read(presenceActionsProvider.notifier).togglePresence(
                  houseId: houseId,
                  newPresence: value ? Presence.home : Presence.away,
                );
          },
          whosAround: _LiveWhosAround(
            members: members,
            homeCount: homeMembers.length,
          ),
          liveActivities: liveActivities,
          resolvedCount: weeklyCount,
          unclaimedCount: unclaimedCount,
        );
      },
    );
  }

  Widget _buildWithMockData(BuildContext context) {
    final homeUsers =
        MockData.users.where((u) => u.presence == 'home').toList();

    return _buildScaffold(
      context: context,
      houseName: 'The Treehouse',
      memberCount: MockData.users.length,
      isHome: _isHome,
      onPresenceChanged: (v) => setState(() => _isHome = v),
      whosAround: _MockWhosAround(homeCount: homeUsers.length),
    );
  }

  Widget _buildScaffold({
    required BuildContext context,
    required String houseName,
    required int memberCount,
    required bool isHome,
    required ValueChanged<bool> onPresenceChanged,
    required Widget whosAround,
    // Live-mode data (null → use mock fallback)
    List<ActivityItem>? liveActivities,
    int? resolvedCount,
    int? unclaimedCount,
  }) {
    final mockActivities = MockData.activities;
    final isLiveMode = liveActivities != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // White card header: title + toggle + who's around
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(40)),
                boxShadow: [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 8)
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row
                      _TitleRow(
                        houseName: houseName,
                        memberCount: memberCount,
                      ),
                      const SizedBox(height: 24),

                      // Presence toggle
                      _PresenceToggle(
                        isHome: isHome,
                        onChanged: onPresenceChanged,
                      ),
                      const SizedBox(height: 24),

                      // Who's around
                      whosAround,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Momentum card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: _MomentumCard(
                onLeaderboardTap: () => context.go('/leaderboard'),
                resolvedCount: resolvedCount,
              ),
            ),
          ),

          // Volunteer nudge (live mode only, when unclaimed rooms exist)
          if (isLiveMode && (unclaimedCount ?? 0) > 0)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.orange100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.orange.withValues(alpha: 0.3)),
                ),
                child: GestureDetector(
                  onTap: () => context.go('/clean'),
                  child: Row(
                    children: [
                      const Icon(Icons.cleaning_services_rounded,
                          color: AppColors.orange, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '$unclaimedCount rooms unclaimed — volunteer!',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.orange,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.orange, size: 20),
                    ],
                  ),
                ),
              ),
            ),

          // Activity header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate800,
                    ),
                  ),
                  const Text(
                    'View all',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Activity feed
          if (isLiveMode)
            SliverPadding(
              padding: const EdgeInsets.only(top: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _LiveActivityItem(
                    activity: liveActivities[index],
                    isLast: index == liveActivities.length - 1,
                  ),
                  childCount: liveActivities.length,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(top: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _ActivityItem(
                    activity: mockActivities[index],
                    isLast: index == mockActivities.length - 1,
                  ),
                  childCount: mockActivities.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Title Row
// ---------------------------------------------------------------------------
class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.houseName, required this.memberCount});

  final String houseName;
  final int memberCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              houseName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 2),
            Text(
              '$memberCount ${memberCount == 1 ? 'Roommate' : 'Roommates'}',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.slate100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: AppColors.slate700,
                size: 24,
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.slate100, width: 2),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Presence Toggle
// ---------------------------------------------------------------------------
class _PresenceToggle extends StatelessWidget {
  const _PresenceToggle({
    required this.isHome,
    required this.onChanged,
  });

  final bool isHome;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // Animated white pill
          AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            alignment:
                isHome ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Labels row
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(true),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      "I'm Home",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isHome
                            ? AppColors.emerald
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(false),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      "I'm Away",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: !isHome
                            ? AppColors.orange
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Who's Around — Live (Firestore)
// ---------------------------------------------------------------------------
class _LiveWhosAround extends StatelessWidget {
  const _LiveWhosAround({
    required this.members,
    required this.homeCount,
  });

  final List<Member> members;
  final int homeCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Who's around?",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.slate800,
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.emerald100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$homeCount Home',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.emerald,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: members.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return _LiveAvatarItem(member: members[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _LiveAvatarItem extends StatelessWidget {
  const _LiveAvatarItem({required this.member});

  final Member member;

  @override
  Widget build(BuildContext context) {
    final isAtHome = member.presence == Presence.home;
    return Opacity(
      opacity: isAtHome ? 1.0 : 0.5,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isAtHome ? AppColors.emerald : AppColors.slate300,
                    width: 2.5,
                  ),
                ),
                child: ClipOval(
                  child: member.avatarUrl != null
                      ? Image.network(
                          member.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.slate200,
                            child: const Icon(
                              Icons.person,
                              color: AppColors.slate400,
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.slate200,
                          child: const Icon(
                            Icons.person,
                            color: AppColors.slate400,
                          ),
                        ),
                ),
              ),
              if (isAtHome)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.emerald,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 56,
            child: Text(
              member.displayName.split(' ').first,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Who's Around — Mock (placeholder mode)
// ---------------------------------------------------------------------------
class _MockWhosAround extends StatelessWidget {
  const _MockWhosAround({required this.homeCount});

  final int homeCount;

  @override
  Widget build(BuildContext context) {
    final users = MockData.users;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Who's around?",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.slate800,
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.emerald100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$homeCount Home',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.emerald,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final user = users[index];
              final isAtHome = user.presence == 'home';
              return _MockAvatarItem(user: user, isAtHome: isAtHome);
            },
          ),
        ),
      ],
    );
  }
}

class _MockAvatarItem extends StatelessWidget {
  const _MockAvatarItem({required this.user, required this.isAtHome});

  final MockUser user;
  final bool isAtHome;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isAtHome ? 1.0 : 0.5,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isAtHome ? AppColors.emerald : AppColors.slate300,
                    width: 2.5,
                  ),
                ),
                child: ClipOval(
                  child: Image.network(
                    user.avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.slate200,
                      child: const Icon(
                          Icons.person, color: AppColors.slate400),
                    ),
                  ),
                ),
              ),
              if (isAtHome)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.emerald,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 56,
            child: Text(
              user.name.split(' ').first,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Momentum Card
// ---------------------------------------------------------------------------
class _MomentumCard extends StatelessWidget {
  const _MomentumCard({
    required this.onLeaderboardTap,
    this.resolvedCount,
  });

  final VoidCallback onLeaderboardTap;
  final int? resolvedCount;

  String get _title {
    if (resolvedCount == null) return 'House on fire!';
    if (resolvedCount! >= 5) return 'House on fire!';
    if (resolvedCount! > 0) return 'Keep it up!';
    return 'Get started!';
  }

  String get _body {
    if (resolvedCount != null) return momentumText(resolvedCount!);
    return 'Your house resolved 12 issues this week. Keep up the momentum!';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.emerald, AppColors.teal],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  color: Color(0xFFFDE047),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _body,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onLeaderboardTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'View Leaderboard',
                style: TextStyle(
                  color: AppColors.emerald,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Activity Feed Item
// ---------------------------------------------------------------------------
class _ActivityItem extends StatelessWidget {
  const _ActivityItem({
    required this.activity,
    required this.isLast,
  });

  final MockActivity activity;
  final bool isLast;

  Color get _dotColor {
    switch (activity.type) {
      case 'created':
        return AppColors.orange;
      case 'resolved':
        return AppColors.emerald;
      case 'disputed':
        return AppColors.rose;
      case 'claimed':
        return AppColors.blue;
      default:
        return AppColors.slate400;
    }
  }

  IconData get _dotIcon {
    switch (activity.type) {
      case 'created':
        return Icons.error_outline;
      case 'resolved':
        return Icons.check_circle_outline;
      case 'disputed':
        return Icons.chat_bubble_outline;
      case 'claimed':
        return Icons.search;
      default:
        return Icons.circle_outlined;
    }
  }

  String get _verb {
    switch (activity.type) {
      case 'created':
        return ' flagged an issue: ';
      case 'resolved':
        return ' resolved ';
      case 'disputed':
        return ' disputed ';
      case 'claimed':
        return ' claimed ';
      default:
        return ' ${activity.type} ';
    }
  }

  int get _points {
    switch (activity.type) {
      case 'resolved':
        return 50;
      case 'claimed':
        return 10;
      case 'created':
        return 10;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/issues/${activity.issue.id}'),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timeline column
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 0, 0),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _dotColor.withValues(alpha: 0.12),
                    ),
                    child: Icon(_dotIcon, color: _dotColor, size: 18),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: AppColors.slate200,
                      ),
                    ),
                ],
              ),
            ),
            // Card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 16, 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                                children: [
                                  TextSpan(
                                    text: activity.user.name.split(' ').first,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary),
                                  ),
                                  TextSpan(
                                    text: _verb,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.textSecondary),
                                  ),
                                  TextSpan(
                                    text: '"${activity.issue.title}"',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            activity.time,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_points > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              '+$_points pts',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.emerald,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Activity Feed Item — Live (Firestore)
// ---------------------------------------------------------------------------
class _LiveActivityItem extends StatelessWidget {
  const _LiveActivityItem({
    required this.activity,
    required this.isLast,
  });

  final ActivityItem activity;
  final bool isLast;

  Color get _dotColor {
    switch (activity.type) {
      case 'created':
        return AppColors.orange;
      case 'resolved':
        return AppColors.emerald;
      case 'badgeEarned':
        return AppColors.yellow400;
      case 'streakMilestone':
        return AppColors.blue;
      case 'deepCleanDone':
        return AppColors.teal;
      default:
        return AppColors.slate400;
    }
  }

  IconData get _dotIcon {
    switch (activity.type) {
      case 'created':
        return Icons.error_outline;
      case 'resolved':
        return Icons.check_circle_outline;
      case 'badgeEarned':
        return Icons.emoji_events;
      case 'streakMilestone':
        return Icons.local_fire_department;
      case 'deepCleanDone':
        return Icons.cleaning_services;
      default:
        return Icons.circle_outlined;
    }
  }

  String get _verb {
    switch (activity.type) {
      case 'created':
        return ' flagged an issue: ';
      case 'resolved':
        return ' resolved ';
      case 'badgeEarned':
        return ' earned a badge: ';
      case 'streakMilestone':
        return ' hit a streak: ';
      case 'deepCleanDone':
        return ' completed deep clean: ';
      default:
        return ' ${activity.type} ';
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: activity.issueId != null
          ? () => context.push('/issues/${activity.issueId}')
          : null,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timeline column
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 0, 0),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _dotColor.withValues(alpha: 0.12),
                    ),
                    child: Icon(_dotIcon, color: _dotColor, size: 18),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: AppColors.slate200,
                      ),
                    ),
                ],
              ),
            ),
            // Card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 16, 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                                children: [
                                  TextSpan(
                                    text: activity.userName.split(' ').first,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary),
                                  ),
                                  TextSpan(
                                    text: _verb,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.textSecondary),
                                  ),
                                  TextSpan(
                                    text: '"${activity.detail}"',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatTime(activity.timestamp),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (activity.points != null &&
                              activity.points! > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              '+${activity.points} pts',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.emerald,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
