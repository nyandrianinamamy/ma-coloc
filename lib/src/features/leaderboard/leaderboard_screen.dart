import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../mock/mock_data.dart';
import '../../theme/app_theme.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  bool _isWeekly = true;

  @override
  Widget build(BuildContext context) {
    // Sort users by points descending
    final sorted = [...MockData.users]
      ..sort((a, b) => b.points.compareTo(a.points));

    final top3 = sorted.take(3).toList();
    final rest = sorted.skip(3).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Dark header
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.slate900,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(40)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      const Text(
                        'Leaderboard',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Weekly/Monthly toggle
                      _PeriodToggle(
                        isWeekly: _isWeekly,
                        onChanged: (v) => setState(() => _isWeekly = v),
                      ),
                      const SizedBox(height: 32),

                      // Podium
                      if (top3.length == 3) _Podium(top3: top3),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Deep Clean callout card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: _DeepCleanCard(onTap: () => context.push('/clean')),
            ),
          ),

          // Rankings header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
              child: Text(
                'Full Rankings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate800,
                ),
              ),
            ),
          ),

          // Remaining users (4th place onward)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final user = rest[index];
                  final rank = index + 4;
                  return _RankingCard(user: user, rank: rank);
                },
                childCount: rest.length,
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
// Period Toggle (Weekly / Monthly)
// ---------------------------------------------------------------------------
class _PeriodToggle extends StatelessWidget {
  const _PeriodToggle({
    required this.isWeekly,
    required this.onChanged,
  });

  final bool isWeekly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.slate800,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          // Animated white sliding pill
          AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            alignment:
                isWeekly ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Labels
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(true),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      'Weekly',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isWeekly
                            ? AppColors.slate900
                            : AppColors.slate400,
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
                      'Monthly',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: !isWeekly
                            ? AppColors.slate900
                            : AppColors.slate400,
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
// Podium
// ---------------------------------------------------------------------------
class _Podium extends StatelessWidget {
  const _Podium({required this.top3});

  final List<MockUser> top3;

  @override
  Widget build(BuildContext context) {
    // top3[0] = 1st, top3[1] = 2nd, top3[2] = 3rd
    // Display order: 2nd (left), 1st (center), 3rd (right)
    return SizedBox(
      height: 240,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 2nd place
          Expanded(
            child: _PodiumColumn(
              user: top3[1],
              rank: 2,
              barHeight: 64,
              avatarBorderColor: AppColors.slate300,
              nameColor: AppColors.slate300,
              pointsColor: AppColors.slate300,
              showTrophy: false,
            ),
          ),
          const SizedBox(width: 8),
          // 1st place (center, tallest)
          Expanded(
            child: _PodiumColumn(
              user: top3[0],
              rank: 1,
              barHeight: 96,
              avatarBorderColor: AppColors.yellow400,
              nameColor: Colors.white,
              pointsColor: AppColors.yellow400,
              showTrophy: true,
            ),
          ),
          const SizedBox(width: 8),
          // 3rd place
          Expanded(
            child: _PodiumColumn(
              user: top3[2],
              rank: 3,
              barHeight: 48,
              avatarBorderColor: AppColors.orange300,
              nameColor: AppColors.orange300,
              pointsColor: AppColors.orange300,
              showTrophy: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  const _PodiumColumn({
    required this.user,
    required this.rank,
    required this.barHeight,
    required this.avatarBorderColor,
    required this.nameColor,
    required this.pointsColor,
    required this.showTrophy,
  });

  final MockUser user;
  final int rank;
  final double barHeight;
  final Color avatarBorderColor;
  final Color nameColor;
  final Color pointsColor;
  final bool showTrophy;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Trophy icon above 1st place
        if (showTrophy) ...[
          const Icon(
            Icons.emoji_events,
            color: AppColors.yellow400,
            size: 28,
          ),
          const SizedBox(height: 4),
        ] else
          const SizedBox(height: 32),

        // Avatar with rank badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: avatarBorderColor, width: 2.5),
              ),
              child: ClipOval(
                child: Image.network(
                  user.avatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.slate700,
                    child: const Icon(Icons.person, color: AppColors.slate400),
                  ),
                ),
              ),
            ),
            // Rank badge (bottom-right of avatar)
            Positioned(
              bottom: -4,
              right: -4,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: avatarBorderColor,
                  border: Border.all(color: AppColors.slate900, width: 2),
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: rank == 1 ? AppColors.slate900 : AppColors.slate900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Name
        Text(
          user.name.split(' ').first,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: nameColor,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),

        // Points
        Text(
          '${user.points} pts',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: pointsColor,
          ),
        ),
        const SizedBox(height: 8),

        // Bar
        Container(
          height: barHeight,
          decoration: BoxDecoration(
            color: AppColors.slate800,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Deep Clean Callout Card
// ---------------------------------------------------------------------------
class _DeepCleanCard extends StatelessWidget {
  const _DeepCleanCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.blue, AppColors.indigo],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.blue.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Sparkles icon in translucent container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Monthly Deep Clean',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '3/5 rooms assigned. Huge points!',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: Colors.white,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ranking Card (4th place and beyond)
// ---------------------------------------------------------------------------
class _RankingCard extends StatelessWidget {
  const _RankingCard({required this.user, required this.rank});

  final MockUser user;
  final int rank;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.slate500,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderMedium, width: 1.5),
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
          const SizedBox(width: 12),

          // Name
          Expanded(
            child: Text(
              user.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // Streak badge
          if (user.streak > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.orange50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    size: 13,
                    color: AppColors.orange,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${user.streak} days',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.orange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Points badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.emerald50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${user.points} pts',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.emerald,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
