import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../mock/mock_data.dart';
import '../../providers/house_provider.dart';
import '../../providers/leaderboard_provider.dart';
import '../../theme/app_theme.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  bool _isWeekly = true;

  @override
  Widget build(BuildContext context) {
    final houseIdAsync = ref.watch(currentHouseIdProvider);
    final houseId = houseIdAsync.valueOrNull;

    // Placeholder mode: debug build with no house ID yet
    final isPlaceholder = kDebugMode && houseId == null;

    if (isPlaceholder) {
      return _buildScaffold(context, _buildMockBody(context));
    }

    if (houseId == null) {
      // In production with no house — show loading until resolved
      if (houseIdAsync.isLoading) {
        return _buildScaffold(
          context,
          const Center(child: CircularProgressIndicator()),
        );
      }
      return _buildScaffold(
        context,
        const Center(child: Text('No house found.')),
      );
    }

    final leaderboardAsync = ref.watch(
      leaderboardProvider(
        LeaderboardParams(houseId: houseId, isWeekly: _isWeekly),
      ),
    );

    return leaderboardAsync.when(
      loading: () => _buildScaffold(
        context,
        const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => _buildScaffold(
        context,
        Center(child: Text('Error: $e')),
      ),
      data: (entries) => _buildScaffold(context, _buildLiveBody(context, entries)),
    );
  }

  Widget _buildScaffold(BuildContext context, Widget body) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: body,
    );
  }

  // ---------------------------------------------------------------------------
  // Mock body (placeholder mode)
  // ---------------------------------------------------------------------------
  Widget _buildMockBody(BuildContext context) {
    final sorted = [...MockData.users]
      ..sort((a, b) => b.points.compareTo(a.points));

    final top3 = sorted.take(3).toList();
    final rest = sorted.skip(3).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeader(
            podium: top3.length == 3 ? _MockPodium(top3: top3) : null,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: _DeepCleanCard(onTap: () => context.push('/clean')),
          ),
        ),
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
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final user = rest[index];
                final rank = index + 4;
                return _MockRankingCard(user: user, rank: rank);
              },
              childCount: rest.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Live body (real Firestore data)
  // ---------------------------------------------------------------------------
  Widget _buildLiveBody(BuildContext context, List<LeaderboardEntry> entries) {
    final top3 = entries.take(3).toList();
    final rest = entries.skip(3).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeader(
            podium: top3.length == 3 ? _LivePodium(top3: top3) : null,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: _DeepCleanCard(onTap: () => context.push('/clean')),
          ),
        ),
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
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final entry = rest[index];
                final rank = index + 4;
                return _LiveRankingCard(entry: entry, rank: rank);
              },
              childCount: rest.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Shared dark header (title + toggle + optional podium)
  // ---------------------------------------------------------------------------
  Widget _buildHeader({Widget? podium}) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.slate900,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Leaderboard',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              _PeriodToggle(
                isWeekly: _isWeekly,
                onChanged: (v) => setState(() => _isWeekly = v),
              ),
              const SizedBox(height: 32),
              if (podium != null) podium,
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Period Toggle (Weekly / Monthly) — unchanged
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
// Mock Podium (uses MockUser)
// ---------------------------------------------------------------------------
class _MockPodium extends StatelessWidget {
  const _MockPodium({required this.top3});

  final List<MockUser> top3;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: _MockPodiumColumn(
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
          Expanded(
            child: _MockPodiumColumn(
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
          Expanded(
            child: _MockPodiumColumn(
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

class _MockPodiumColumn extends StatelessWidget {
  const _MockPodiumColumn({
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
        if (showTrophy) ...[
          const Icon(Icons.emoji_events, color: AppColors.yellow400, size: 28),
          const SizedBox(height: 4),
        ] else
          const SizedBox(height: 32),
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
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
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
        Text(
          '${user.points} pts',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: pointsColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: barHeight,
          decoration: const BoxDecoration(
            color: AppColors.slate800,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Live Podium (uses LeaderboardEntry)
// ---------------------------------------------------------------------------
class _LivePodium extends StatelessWidget {
  const _LivePodium({required this.top3});

  final List<LeaderboardEntry> top3;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: _LivePodiumColumn(
              entry: top3[1],
              rank: 2,
              barHeight: 64,
              avatarBorderColor: AppColors.slate300,
              nameColor: AppColors.slate300,
              pointsColor: AppColors.slate300,
              showTrophy: false,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _LivePodiumColumn(
              entry: top3[0],
              rank: 1,
              barHeight: 96,
              avatarBorderColor: AppColors.yellow400,
              nameColor: Colors.white,
              pointsColor: AppColors.yellow400,
              showTrophy: true,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _LivePodiumColumn(
              entry: top3[2],
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

class _LivePodiumColumn extends StatelessWidget {
  const _LivePodiumColumn({
    required this.entry,
    required this.rank,
    required this.barHeight,
    required this.avatarBorderColor,
    required this.nameColor,
    required this.pointsColor,
    required this.showTrophy,
  });

  final LeaderboardEntry entry;
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
        if (showTrophy) ...[
          const Icon(Icons.emoji_events, color: AppColors.yellow400, size: 28),
          const SizedBox(height: 4),
        ] else
          const SizedBox(height: 32),
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
                child: entry.avatarUrl != null
                    ? Image.network(
                        entry.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _defaultAvatar(),
                      )
                    : _defaultAvatar(),
              ),
            ),
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
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          entry.displayName.split(' ').first,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: nameColor,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '${entry.periodPoints} pts',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: pointsColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: barHeight,
          decoration: const BoxDecoration(
            color: AppColors.slate800,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: AppColors.slate700,
      child: const Icon(Icons.person, color: AppColors.slate400),
    );
  }
}

// ---------------------------------------------------------------------------
// Deep Clean Callout Card — unchanged except subtitle text
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
                    'Earn bonus points!',
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
// Mock Ranking Card (4th place and beyond — uses MockUser)
// ---------------------------------------------------------------------------
class _MockRankingCard extends StatelessWidget {
  const _MockRankingCard({required this.user, required this.rank});

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
          BoxShadow(
              color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
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
          if (user.streak > 0) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

// ---------------------------------------------------------------------------
// Live Ranking Card (4th place and beyond — uses LeaderboardEntry)
// ---------------------------------------------------------------------------
class _LiveRankingCard extends StatelessWidget {
  const _LiveRankingCard({required this.entry, required this.rank});

  final LeaderboardEntry entry;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final streak = entry.stats.currentStreak;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderMedium, width: 1.5),
            ),
            child: ClipOval(
              child: entry.avatarUrl != null
                  ? Image.network(
                      entry.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.slate200,
                        child: const Icon(Icons.person,
                            color: AppColors.slate400),
                      ),
                    )
                  : Container(
                      color: AppColors.slate200,
                      child: const Icon(Icons.person,
                          color: AppColors.slate400),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.displayName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (streak > 0) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    '$streak days',
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
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.emerald50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${entry.periodPoints} pts',
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
