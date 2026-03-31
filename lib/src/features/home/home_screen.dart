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
          SliverToBoxAdapter(child: _Header()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _PresenceToggle(
                isHome: _isHome,
                onChanged: (v) => setState(() => _isHome = v),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
              child: _WhosAround(homeCount: homeUsers.length),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: _MomentumCard(
                onLeaderboardTap: () => context.go('/leaderboard'),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _ActivityItem(
                activity: activities[index],
                isLast: index == activities.length - 1,
              ),
              childCount: activities.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
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
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                color: AppColors.textPrimary,
                onPressed: () {},
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.orange,
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
          // Animated pill
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment:
                isHome ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isHome ? AppColors.emerald : AppColors.orange,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (isHome ? AppColors.emerald : AppColors.orange)
                          .withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
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
                            isHome ? Colors.white : AppColors.textSecondary,
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
                            !isHome ? Colors.white : AppColors.textSecondary,
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Text(
                "Who's around?",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.emerald100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$homeCount Home',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.emerald,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 88,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
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
    final topUser = MockData.users
        .reduce((a, b) => a.points > b.points ? a : b);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.emerald, AppColors.teal],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Text('🔥', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 6),
                    Text(
                      'House on fire!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${topUser.name} leads with ${topUser.points} pts  •  ${topUser.streak} day streak',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: onLeaderboardTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4), width: 1),
                    ),
                    child: const Text(
                      'View Leaderboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
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
      case 'opened':
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
      case 'opened':
        return Icons.add_circle_outline;
      case 'resolved':
        return Icons.check_circle_outline;
      case 'disputed':
        return Icons.error_outline;
      case 'claimed':
        return Icons.person_outline;
      default:
        return Icons.circle_outlined;
    }
  }

  String get _verb {
    switch (activity.type) {
      case 'opened':
        return 'opened';
      case 'resolved':
        return 'resolved';
      case 'disputed':
        return 'disputed';
      case 'claimed':
        return 'claimed';
      default:
        return activity.type;
    }
  }

  int get _points {
    switch (activity.type) {
      case 'resolved':
        return 50;
      case 'claimed':
        return 10;
      case 'opened':
        return 5;
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
                                  text: activity.user.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                                TextSpan(
                                  text: ' $_verb ',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.textSecondary),
                                ),
                                TextSpan(
                                  text: activity.issue.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
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
    );
  }
}
