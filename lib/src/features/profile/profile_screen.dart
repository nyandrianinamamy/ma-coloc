import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../mock/mock_data.dart';
import '../../models/badge.dart';
import '../../models/member.dart';
import '../../providers/auth_provider.dart';
import '../../providers/house_provider.dart';
import '../../providers/member_provider.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final houseIdAsync = ref.watch(currentHouseIdProvider);
    final houseId = houseIdAsync.valueOrNull;

    // Placeholder mode: debug build and no house yet
    if (kDebugMode && houseId == null) {
      return const _MockProfileScreen();
    }

    if (houseId == null) {
      return const _MockProfileScreen();
    }

    final authAsync = ref.watch(authStateProvider);
    final uid = authAsync.valueOrNull?.uid;

    final membersAsync = ref.watch(membersStreamProvider(houseId));
    final houseAsync = ref.watch(currentHouseProvider);

    final member = membersAsync.valueOrNull?.where((m) => m.uid == uid).firstOrNull;
    final houseName = houseAsync.valueOrNull?.name ?? 'My House';

    if (member == null) {
      return const _MockProfileScreen();
    }

    final stats = member.stats;
    final earnedIds = stats.badges.toSet();
    final earnedBadges = badgeCatalog.values.where((b) => earnedIds.contains(b.id)).toList();
    final lockedBadges = badgeCatalog.values.where((b) => !earnedIds.contains(b.id)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LiveProfileHeader(member: member, houseName: houseName),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LiveStatsGrid(stats: stats),
                  const SizedBox(height: 28),
                  _LiveBadgesSection(
                    earnedBadges: earnedBadges,
                    lockedBadges: lockedBadges,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Mock Profile (placeholder) ───────────────────────────────────────────────

class _MockProfileScreen extends StatelessWidget {
  const _MockProfileScreen();

  @override
  Widget build(BuildContext context) {
    final user = MockData.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MockProfileHeader(user: user),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MockStatsGrid(user: user),
                  const SizedBox(height: 28),
                  _MockBadgesSection(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Live Header ──────────────────────────────────────────────────────────────

class _LiveProfileHeader extends StatelessWidget {
  const _LiveProfileHeader({required this.member, required this.houseName});

  final Member member;
  final String houseName;

  @override
  Widget build(BuildContext context) {
    final isHome = member.presence == Presence.home;
    final presenceColor = isHome ? AppColors.emerald : AppColors.slate400;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            children: [
              // Settings gear top-right
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => context.push('/settings'),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.settings_outlined,
                      size: 20,
                      color: AppColors.slate500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Avatar with presence dot
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: AppColors.slate100,
                      backgroundImage: member.avatarUrl != null
                          ? NetworkImage(member.avatarUrl!)
                          : null,
                      child: member.avatarUrl == null
                          ? const Icon(Icons.person, size: 48, color: AppColors.slate400)
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: presenceColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Name
              Text(
                member.displayName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate800,
                ),
              ),
              const SizedBox(height: 6),
              // House location
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.slate500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    houseName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Live Stats Grid ──────────────────────────────────────────────────────────

class _LiveStatsGrid extends StatelessWidget {
  const _LiveStatsGrid({required this.stats});

  final MemberStats stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      children: [
        _StatCard(
          iconBgColor: AppColors.orange100,
          icon: Icons.emoji_events_rounded,
          iconColor: AppColors.orange,
          value: '${stats.totalPoints}',
          label: 'TOTAL PTS',
        ),
        _StatCard(
          iconBgColor: AppColors.rose100,
          icon: Icons.local_fire_department_rounded,
          iconColor: AppColors.rose,
          value: '${stats.currentStreak}',
          label: 'DAY STREAK',
        ),
        _StatCard(
          iconBgColor: AppColors.blue100,
          icon: Icons.bolt_rounded,
          iconColor: AppColors.blue,
          value: '${stats.issuesResolved}',
          label: 'RESOLVED',
        ),
        _StatCard(
          iconBgColor: AppColors.slate100,
          icon: Icons.shield_outlined,
          iconColor: AppColors.slate500,
          value: '${stats.issuesCreated}',
          label: 'CREATED',
        ),
      ],
    );
  }
}

// ─── Live Badges Section ──────────────────────────────────────────────────────

class _LiveBadgesSection extends StatelessWidget {
  const _LiveBadgesSection({
    required this.earnedBadges,
    required this.lockedBadges,
  });

  final List<BadgeDefinition> earnedBadges;
  final List<BadgeDefinition> lockedBadges;

  LinearGradient _gradientForBadge(String id) {
    if (id == 'first_issue' || id == 'points_100') {
      return const LinearGradient(
        colors: [Color(0xFFFEF9C3), Color(0xFFFEF08A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (id == 'ten_resolved' || id == 'fifty_resolved') {
      return const LinearGradient(
        colors: [AppColors.blue100, AppColors.blue],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (id == 'streak_7' || id == 'streak_30') {
      return LinearGradient(
        colors: [AppColors.orange100, AppColors.orange],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    // deep_clean_1, deep_clean_10
    return const LinearGradient(
      colors: [AppColors.emerald100, AppColors.emerald],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Color _iconColorForBadge(String id) {
    if (id == 'first_issue' || id == 'points_100') {
      return AppColors.yellow400;
    }
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Badges (${earnedBadges.length})',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.slate800,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.slate100),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...earnedBadges.asMap().entries.map((entry) {
                  final i = entry.key;
                  final badge = entry.value;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (i > 0) const SizedBox(width: 20),
                      _BadgeItem(
                        icon: badge.icon,
                        label: badge.name,
                        gradient: _gradientForBadge(badge.id),
                        iconColor: _iconColorForBadge(badge.id),
                        hasBorder: true,
                      ),
                    ],
                  );
                }),
                ...lockedBadges.asMap().entries.map((entry) {
                  final badge = entry.value;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 20),
                      _LockedBadge(label: badge.name),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Shared StatCard ──────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.iconBgColor,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final Color iconBgColor;
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.slate500,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Badge Widgets ─────────────────────────────────────────────────────

class _BadgeItem extends StatelessWidget {
  const _BadgeItem({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.iconColor,
    this.hasBorder = false,
  });

  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final Color iconColor;
  final bool hasBorder;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: gradient,
            shape: BoxShape.circle,
            border: hasBorder
                ? Border.all(color: Colors.white, width: 3)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: iconColor, size: 32),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.slate700,
          ),
        ),
      ],
    );
  }
}

class _LockedBadge extends StatelessWidget {
  const _LockedBadge({this.label = 'Locked'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.5,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.slate100,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.slate300,
                width: 2,
              ),
            ),
            child: CustomPaint(
              painter: _DashedCirclePainter(color: AppColors.slate300),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.slate400,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.slate500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashCount = 16;
    const gapFraction = 0.4;
    final radius = (size.width / 2) - 1;
    const fullAngle = 2 * 3.141592653589793;
    final dashAngle = fullAngle / dashCount * (1 - gapFraction);
    final gapAngle = fullAngle / dashCount * gapFraction;

    final center = Offset(size.width / 2, size.height / 2);

    double startAngle = -3.141592653589793 / 2;
    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
      startAngle += dashAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Mock Header ──────────────────────────────────────────────────────────────

class _MockProfileHeader extends StatelessWidget {
  const _MockProfileHeader({required this.user});

  final MockUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            children: [
              // Settings gear top-right
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => context.push('/settings'),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.settings_outlined,
                      size: 20,
                      color: AppColors.slate500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Avatar with online dot
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 56,
                      backgroundImage: NetworkImage(user.avatarUrl),
                      backgroundColor: AppColors.slate100,
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.emerald,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Name
              Text(
                user.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate800,
                ),
              ),
              const SizedBox(height: 6),
              // Location
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.slate500,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'The Treehouse',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Mock Stats Grid ──────────────────────────────────────────────────────────

class _MockStatsGrid extends StatelessWidget {
  const _MockStatsGrid({required this.user});

  final MockUser user;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      children: [
        _StatCard(
          iconBgColor: AppColors.orange100,
          icon: Icons.emoji_events_rounded,
          iconColor: AppColors.orange,
          value: '${user.points}',
          label: 'TOTAL PTS',
        ),
        _StatCard(
          iconBgColor: AppColors.rose100,
          icon: Icons.local_fire_department_rounded,
          iconColor: AppColors.rose,
          value: '${user.streak}',
          label: 'DAY STREAK',
        ),
        _StatCard(
          iconBgColor: AppColors.blue100,
          icon: Icons.bolt_rounded,
          iconColor: AppColors.blue,
          value: '42',
          label: 'RESOLVED',
        ),
        _StatCard(
          iconBgColor: AppColors.slate100,
          icon: Icons.shield_outlined,
          iconColor: AppColors.slate500,
          value: '12',
          label: 'CREATED',
        ),
      ],
    );
  }
}

// ─── Mock Badges Section ──────────────────────────────────────────────────────

class _MockBadgesSection extends StatelessWidget {
  const _MockBadgesSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Badges (3)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.slate800,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.slate100),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _BadgeItem(
                  icon: Icons.star_rounded,
                  label: 'Clean Freak',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFEF9C3), Color(0xFFFEF08A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  iconColor: AppColors.yellow400,
                  hasBorder: true,
                ),
                const SizedBox(width: 20),
                _BadgeItem(
                  icon: Icons.bolt_rounded,
                  label: 'Fast Act',
                  gradient: const LinearGradient(
                    colors: [AppColors.emerald100, AppColors.emerald],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  iconColor: Colors.white,
                  hasBorder: true,
                ),
                const SizedBox(width: 20),
                _BadgeItem(
                  icon: Icons.shield_rounded,
                  label: 'Founder',
                  gradient: const LinearGradient(
                    colors: [AppColors.blue100, AppColors.blue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  iconColor: Colors.white,
                  hasBorder: true,
                ),
                const SizedBox(width: 20),
                const _LockedBadge(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
