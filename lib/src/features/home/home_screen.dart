import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../mock/mock_data.dart';
import '../../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isHome = true;

  @override
  Widget build(BuildContext context) {
    final homeUsers =
        MockData.users.where((u) => u.presence == 'home').toList();
    final activities = MockData.activities;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // White card header: title + toggle + who's around
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
                boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 8)],
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'The Treehouse',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '6 Roommates',
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
                      ),
                      const SizedBox(height: 24),

                      // Presence toggle
                      _PresenceToggle(
                        isHome: _isHome,
                        onChanged: (v) => setState(() => _isHome = v),
                      ),
                      const SizedBox(height: 24),

                      // Who's around
                      _WhosAround(homeCount: homeUsers.length),
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
                  Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate800,
                    ),
                  ),
                  Text(
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
          SliverPadding(
            padding: const EdgeInsets.only(top: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _ActivityItem(
                  activity: activities[index],
                  isLast: index == activities.length - 1,
                ),
                childCount: activities.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
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
                        color:
                            isHome ? AppColors.emerald : AppColors.textSecondary,
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
                        color:
                            !isHome ? AppColors.orange : AppColors.textSecondary,
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
// Who's Around
// ---------------------------------------------------------------------------
class _WhosAround extends StatelessWidget {
  const _WhosAround({required this.homeCount});

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
            Text(
              "Who's around?",
              style: const TextStyle(
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
              return _AvatarItem(user: user, isAtHome: isAtHome);
            },
          ),
        ),
      ],
    );
  }
}

class _AvatarItem extends StatelessWidget {
  const _AvatarItem({required this.user, required this.isAtHome});

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
                    color:
                        isAtHome ? AppColors.emerald : AppColors.slate300,
                    width: 2.5,
                  ),
                ),
                child: ClipOval(
                  child: Image.network(
                    user.avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.slate200,
                      child: const Icon(Icons.person, color: AppColors.slate400),
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
  const _MomentumCard({required this.onLeaderboardTap});

  final VoidCallback onLeaderboardTap;

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
              const Text(
                'House on fire!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your house resolved 12 issues this week. Keep up the momentum!',
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
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
    return IntrinsicHeight(
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
              child: GestureDetector(
                onTap: () => context.push('/issues/${activity.issue.id}'),
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
          ),
        ],
      ),
    );
  }
}
