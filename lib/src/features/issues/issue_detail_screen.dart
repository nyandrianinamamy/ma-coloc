import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../mock/mock_data.dart';
import '../../theme/app_theme.dart';

class IssueDetailScreen extends StatelessWidget {
  const IssueDetailScreen({super.key, required this.issueId});

  final String issueId;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  MockIssue? _findIssue() {
    try {
      return MockData.issues.firstWhere((i) => i.id == issueId);
    } catch (_) {
      return null;
    }
  }

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'chore':
        return AppColors.orange;
      case 'grocery':
        return AppColors.emerald;
      case 'repair':
        return AppColors.blue;
      case 'other':
        return AppColors.indigo;
      default:
        return AppColors.slate400;
    }
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'chore':
        return Icons.cleaning_services_outlined;
      case 'grocery':
        return Icons.shopping_cart_outlined;
      case 'repair':
        return Icons.build_outlined;
      case 'other':
        return Icons.category_outlined;
      default:
        return Icons.help_outline;
    }
  }

  ({
    Color color,
    Color dotColor,
    IconData iconData,
    String label,
  }) _statusConfig(String status) {
    switch (status) {
      case 'open':
        return (
          color: AppColors.orange,
          dotColor: AppColors.orange,
          iconData: Icons.radio_button_unchecked,
          label: 'OPEN',
        );
      case 'in-progress':
        return (
          color: AppColors.blue,
          dotColor: AppColors.blue,
          iconData: Icons.autorenew,
          label: 'IN PROGRESS',
        );
      case 'resolved':
        return (
          color: AppColors.emerald,
          dotColor: AppColors.emerald,
          iconData: Icons.check_circle_outline,
          label: 'RESOLVED',
        );
      case 'disputed':
        return (
          color: AppColors.rose,
          dotColor: AppColors.rose,
          iconData: Icons.chat_bubble_outline,
          label: 'DISPUTED',
        );
      default:
        return (
          color: AppColors.slate400,
          dotColor: AppColors.slate400,
          iconData: Icons.help_outline,
          label: status.toUpperCase(),
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final issue = _findIssue();

    if (issue == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: Text('Issue not found')),
      );
    }

    final author = MockData.userById(issue.authorId);
    final assignee =
        issue.assigneeId != null ? MockData.userById(issue.assigneeId!) : null;
    final status = _statusConfig(issue.status);
    final typeColor = _typeColor(issue.type);
    final typeIcon = _typeIcon(issue.type);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Scrollable content
          CustomScrollView(
            slivers: [
              // ----------------------------------------------------------------
              // Photo Header
              // ----------------------------------------------------------------
              SliverToBoxAdapter(
                child: _PhotoHeader(
                  issue: issue,
                  typeColor: typeColor,
                  typeIcon: typeIcon,
                  status: status,
                  onBack: () => context.pop(),
                ),
              ),

              // ----------------------------------------------------------------
              // Content
              // ----------------------------------------------------------------
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Author / Assignee card
                    _AuthorAssigneeCard(
                      author: author,
                      assignee: assignee,
                      createdAt: issue.createdAt,
                    ),
                    const SizedBox(height: 20),

                    // Description
                    _SectionLabel(label: 'DESCRIPTION'),
                    const SizedBox(height: 8),
                    _DescriptionCard(description: issue.description),
                    const SizedBox(height: 20),

                    // Timeline
                    _SectionLabel(label: 'TIMELINE'),
                    const SizedBox(height: 8),
                    _TimelineSection(
                      issue: issue,
                      author: author,
                      assignee: assignee,
                    ),
                  ]),
                ),
              ),
            ],
          ),

          // ----------------------------------------------------------------
          // Bottom action bar (fixed)
          // ----------------------------------------------------------------
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomActionBar(status: issue.status),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Photo Header
// =============================================================================

class _PhotoHeader extends StatelessWidget {
  const _PhotoHeader({
    required this.issue,
    required this.typeColor,
    required this.typeIcon,
    required this.status,
    required this.onBack,
  });

  final MockIssue issue;
  final Color typeColor;
  final IconData typeIcon;
  final ({Color color, Color dotColor, IconData iconData, String label}) status;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: 288,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background: colored gradient placeholder
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  typeColor.withValues(alpha: 0.25),
                  typeColor.withValues(alpha: 0.10),
                ],
              ),
            ),
            child: Center(
              child: Icon(
                typeIcon,
                size: 80,
                color: typeColor.withValues(alpha: 0.35),
              ),
            ),
          ),

          // Dark gradient overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.4, 1.0],
                colors: [
                  Color(0x66000000), // black/40
                  Color(0x00000000), // transparent
                  Color(0xCC000000), // black/80
                ],
              ),
            ),
          ),

          // Top nav
          Positioned(
            top: topPadding + 8,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button
                _GlassCircleButton(
                  onTap: onBack,
                  child: const Icon(
                    Icons.chevron_left,
                    color: Colors.white,
                    size: 22,
                  ),
                ),

                // Type badge pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0x33000000),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    issue.type.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                // More button
                _GlassCircleButton(
                  onTap: () {},
                  child: const Icon(
                    Icons.more_horiz,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          // Bottom: status + title
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status row
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: status.dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status.label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Title
                Text(
                  issue.title,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
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

// Glass circle button
class _GlassCircleButton extends StatelessWidget {
  const _GlassCircleButton({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Color(0x33000000),
          shape: BoxShape.circle,
        ),
        child: Center(child: child),
      ),
    );
  }
}

// =============================================================================
// Author / Assignee card
// =============================================================================

class _AuthorAssigneeCard extends StatelessWidget {
  const _AuthorAssigneeCard({
    required this.author,
    required this.assignee,
    required this.createdAt,
  });

  final MockUser? author;
  final MockUser? assignee;
  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    final timeStr = timeago.format(createdAt);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderMedium),
      ),
      child: Row(
        children: [
          // Author side
          Expanded(
            child: Row(
              children: [
                _AvatarCircle(user: author, size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author?.name ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 11,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            timeStr,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 36,
            color: AppColors.border,
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),

          // Assignee side
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'ASSIGNEE',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTertiary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              assignee != null
                  ? Row(
                      children: [
                        Text(
                          assignee!.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.slate800,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _AvatarCircle(user: assignee, size: 28),
                      ],
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.orange50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.orange300),
                      ),
                      child: const Text(
                        'Unassigned',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
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

// =============================================================================
// Avatar circle
// =============================================================================

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({required this.user, required this.size});

  final MockUser? user;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.slate200,
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: ClipOval(
        child: user != null
            ? Image.network(
                user!.avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.person,
                  size: size * 0.55,
                  color: AppColors.slate400,
                ),
              )
            : Icon(
                Icons.person,
                size: size * 0.55,
                color: AppColors.slate400,
              ),
      ),
    );
  }
}

// =============================================================================
// Section label
// =============================================================================

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.textTertiary,
        letterSpacing: 1.5,
      ),
    );
  }
}

// =============================================================================
// Description card
// =============================================================================

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderMedium),
      ),
      child: Text(
        description,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          height: 1.5,
        ),
      ),
    );
  }
}

// =============================================================================
// Timeline section
// =============================================================================

class _TimelineSection extends StatelessWidget {
  const _TimelineSection({
    required this.issue,
    required this.author,
    required this.assignee,
  });

  final MockIssue issue;
  final MockUser? author;
  final MockUser? assignee;

  @override
  Widget build(BuildContext context) {
    final timeStr = timeago.format(issue.createdAt);
    final steps = <_TimelineStep>[];

    // Step 1: Issue Reported (always)
    steps.add(_TimelineStep(
      iconBg: AppColors.slate100,
      icon: Icons.error_outline,
      iconColor: AppColors.rose,
      title: 'Issue Reported',
      subtitle: '$timeStr by ${author?.name ?? 'Unknown'}',
      isLast: false,
    ));

    // Step 2: Claimed (if assignee exists)
    if (assignee != null) {
      steps.add(_TimelineStep(
        iconBg: AppColors.blue100,
        icon: Icons.person_outline,
        iconColor: AppColors.blue,
        title: 'Claimed',
        subtitle: 'by ${assignee!.name}',
        isLast: false,
      ));
    }

    // Step 3: Resolved (if status=resolved)
    if (issue.status == 'resolved') {
      steps.add(_TimelineStep(
        iconBg: AppColors.emerald,
        icon: Icons.check,
        iconColor: Colors.white,
        title: 'Resolved',
        subtitle: 'Pending 24h dispute window',
        isLast: true,
      ));
    }

    // Step 3 (alt): Disputed (if status=disputed)
    if (issue.status == 'disputed') {
      steps.add(_TimelineStep(
        iconBg: AppColors.rose,
        icon: Icons.warning_rounded,
        iconColor: Colors.white,
        title: 'Disputed',
        subtitle: 'by ${assignee?.name ?? 'Someone'}. "Still dirty!"',
        isLast: true,
      ));
    }

    // Mark last step
    if (steps.isNotEmpty) {
      final lastIdx = steps.length - 1;
      steps[lastIdx] = steps[lastIdx].copyWithIsLast(true);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderMedium),
      ),
      child: Column(
        children: steps,
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isLast,
  });

  final Color iconBg;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isLast;

  _TimelineStep copyWithIsLast(bool last) => _TimelineStep(
        iconBg: iconBg,
        icon: icon,
        iconColor: iconColor,
        title: title,
        subtitle: subtitle,
        isLast: last,
      );

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: icon + connector line
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 16, color: iconColor),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.border,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Right: title + subtitle
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Bottom action bar
// =============================================================================

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPadding),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        border: const Border(
          top: BorderSide(color: AppColors.borderMedium),
        ),
      ),
      child: _buildActions(context),
    );
  }

  Widget _buildActions(BuildContext context) {
    switch (status) {
      case 'open':
        return _ActionButton(
          label: 'Claim Issue (+50 pts)',
          backgroundColor: AppColors.orange,
          textColor: Colors.white,
          icon: Icons.arrow_forward_rounded,
          onTap: () {},
        );

      case 'in-progress':
        return _ActionButton(
          label: 'Mark Resolved',
          backgroundColor: AppColors.emerald,
          textColor: Colors.white,
          icon: Icons.check_rounded,
          onTap: () {},
        );

      case 'resolved':
        return Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Dispute',
                backgroundColor: Colors.white,
                textColor: AppColors.rose,
                borderColor: AppColors.rose,
                icon: Icons.warning_rounded,
                iconColor: AppColors.rose,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                label: 'Props',
                backgroundColor: AppColors.emerald50,
                textColor: AppColors.emerald,
                icon: Icons.celebration_outlined,
                iconColor: AppColors.emerald,
                onTap: () {},
              ),
            ),
          ],
        );

      case 'disputed':
        return const Center(
          child: Text(
            'No actions available',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
    required this.onTap,
    this.borderColor,
    this.iconColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;
  final VoidCallback onTap;
  final Color? borderColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: borderColor != null
              ? Border.all(color: borderColor!, width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              icon,
              size: 18,
              color: iconColor ?? textColor,
            ),
          ],
        ),
      ),
    );
  }
}
