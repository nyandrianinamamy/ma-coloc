import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../firebase_options.dart';
import '../../mock/mock_data.dart';
import '../../models/issue.dart';
import '../../providers/auth_provider.dart';
import '../../providers/house_provider.dart';
import '../../providers/issue_provider.dart';
import '../../theme/app_theme.dart';

class IssueDetailScreen extends ConsumerWidget {
  const IssueDetailScreen({super.key, required this.issueId});

  final String issueId;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Color _typeColor(IssueType type) {
    switch (type) {
      case IssueType.chore:
        return AppColors.orange;
      case IssueType.grocery:
        return AppColors.emerald;
      case IssueType.repair:
        return AppColors.blue;
      case IssueType.other:
        return AppColors.indigo;
    }
  }

  IconData _typeIcon(IssueType type) {
    switch (type) {
      case IssueType.chore:
        return Icons.cleaning_services_outlined;
      case IssueType.grocery:
        return Icons.shopping_cart_outlined;
      case IssueType.repair:
        return Icons.build_outlined;
      case IssueType.other:
        return Icons.category_outlined;
    }
  }

  ({
    Color color,
    Color dotColor,
    IconData iconData,
    String label,
  }) _statusConfig(IssueStatus status) {
    switch (status) {
      case IssueStatus.open:
        return (
          color: AppColors.orange,
          dotColor: AppColors.orange,
          iconData: Icons.radio_button_unchecked,
          label: 'OPEN',
        );
      case IssueStatus.inProgress:
        return (
          color: AppColors.blue,
          dotColor: AppColors.blue,
          iconData: Icons.autorenew,
          label: 'IN PROGRESS',
        );
      case IssueStatus.resolved:
        return (
          color: AppColors.emerald,
          dotColor: AppColors.emerald,
          iconData: Icons.check_circle_outline,
          label: 'RESOLVED',
        );
      case IssueStatus.disputed:
        return (
          color: AppColors.rose,
          dotColor: AppColors.rose,
          iconData: Icons.chat_bubble_outline,
          label: 'DISPUTED',
        );
      case IssueStatus.closed:
        return (
          color: AppColors.slate400,
          dotColor: AppColors.slate400,
          iconData: Icons.lock_outline,
          label: 'CLOSED',
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  /// Converts a [MockIssue] to an [Issue] for placeholder mode.
  static Issue? _mockIssueById(String id) {
    final match = MockData.issues.where((m) => m.id == id).toList();
    if (match.isEmpty) return null;
    final m = match.first;
    IssueType type;
    switch (m.type.toLowerCase()) {
      case 'grocery':
        type = IssueType.grocery;
      case 'repair':
        type = IssueType.repair;
      case 'other':
        type = IssueType.other;
      default:
        type = IssueType.chore;
    }
    IssueStatus status;
    switch (m.status.toLowerCase()) {
      case 'in-progress':
        status = IssueStatus.inProgress;
      case 'resolved':
        status = IssueStatus.resolved;
      case 'disputed':
        status = IssueStatus.disputed;
      case 'closed':
        status = IssueStatus.closed;
      default:
        status = IssueStatus.open;
    }
    return Issue(
      id: m.id,
      type: type,
      title: m.title,
      description: m.description,
      photoUrl: m.photoUrl,
      createdBy: m.authorId,
      assignedTo: m.assigneeId,
      anonymous: false,
      createdAt: Timestamp.fromDate(m.createdAt),
      status: status,
      points: Issue.pointsForType(type),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaceholder =
        kDebugMode && DefaultFirebaseOptions.isPlaceholder;

    final String houseId;
    final String? currentUid;
    Issue? issue;

    if (isPlaceholder) {
      houseId = 'placeholder';
      currentUid = null;
      issue = _mockIssueById(issueId);
    } else {
      final houseIdValue =
          ref.watch(currentHouseIdProvider).valueOrNull;
      currentUid = ref.watch(authStateProvider).valueOrNull?.uid;

      if (houseIdValue == null) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => context.pop(),
            ),
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      houseId = houseIdValue;
    }

    if (isPlaceholder) {
      return _buildDetail(
        context,
        ref,
        issue: issue,
        houseId: houseId,
        currentUid: currentUid,
        isPlaceholder: true,
      );
    }

    final issueAsync = ref.watch(issueDetailProvider((houseId, issueId)));

    return issueAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(child: Text('Error: $e')),
      ),
      data: (loadedIssue) => _buildDetail(
        context,
        ref,
        issue: loadedIssue,
        houseId: houseId,
        currentUid: currentUid,
        isPlaceholder: false,
      ),
    );
  }

  Widget _buildDetail(
    BuildContext context,
    WidgetRef ref, {
    required Issue? issue,
    required String houseId,
    required String? currentUid,
    required bool isPlaceholder,
  }) {
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
                      createdBy: issue.createdBy,
                      anonymous: issue.anonymous,
                      assignedTo: issue.assignedTo,
                      createdAt: issue.createdAt,
                    ),
                    const SizedBox(height: 20),

                    // Description
                    const _SectionLabel(label: 'DESCRIPTION'),
                    const SizedBox(height: 8),
                    _DescriptionCard(
                      description: issue.description ?? '—',
                    ),
                    const SizedBox(height: 20),

                    // Timeline
                    const _SectionLabel(label: 'TIMELINE'),
                    const SizedBox(height: 8),
                    _TimelineSection(issue: issue),
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
            child: _BottomActionBar(
              issue: issue,
              currentUid: currentUid,
              onClaim: isPlaceholder
                  ? () {}
                  : () {
                      ref
                          .read(issueActionsProvider.notifier)
                          .claim(houseId: houseId, issueId: issueId);
                    },
              onResolve: isPlaceholder
                  ? () {}
                  : () => _showResolveSheet(
                        context,
                        ref,
                        houseId: houseId,
                        issueId: issueId,
                      ),
              onDispute: isPlaceholder
                  ? () {}
                  : () => _showDisputeDialog(
                        context,
                        ref,
                        houseId: houseId,
                        issueId: issueId,
                        issue: issue,
                      ),
              onReact: isPlaceholder
                  ? () {}
                  : () {
                      ref.read(issueActionsProvider.notifier).react(
                            houseId: houseId,
                            issueId: issueId,
                            emoji: '👏',
                          );
                    },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Resolve bottom sheet
  // ---------------------------------------------------------------------------

  void _showResolveSheet(
    BuildContext context,
    WidgetRef ref, {
    required String houseId,
    required String issueId,
  }) {
    final noteController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            24,
            16,
            16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resolution Note (optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate800,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'How did you fix it?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    ref.read(issueActionsProvider.notifier).resolve(
                          houseId: houseId,
                          issueId: issueId,
                          note: noteController.text.trim().isEmpty
                              ? null
                              : noteController.text.trim(),
                        );
                  },
                  child: const Text(
                    'Confirm Resolution',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Dispute dialog
  // ---------------------------------------------------------------------------

  void _showDisputeDialog(
    BuildContext context,
    WidgetRef ref, {
    required String houseId,
    required String issueId,
    required Issue issue,
  }) {
    final reasonController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Dispute Resolution'),
          content: TextField(
            controller: reasonController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Why are you disputing?',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                ref.read(issueActionsProvider.notifier).dispute(
                      houseId: houseId,
                      issueId: issueId,
                      reason: reasonController.text.trim(),
                      resolvedByUid: issue.resolvedBy!,
                    );
              },
              child: const Text(
                'Dispute',
                style: TextStyle(color: AppColors.rose),
              ),
            ),
          ],
        );
      },
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

  final Issue issue;
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
                    issue.type.name.toUpperCase(),
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
                  issue.title ?? 'Untitled Issue',
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
    required this.createdBy,
    required this.anonymous,
    required this.assignedTo,
    required this.createdAt,
  });

  final String createdBy;
  final bool anonymous;
  final String? assignedTo;
  final Timestamp createdAt;

  @override
  Widget build(BuildContext context) {
    final timeStr = timeago.format(createdAt.toDate());
    final authorLabel = anonymous ? 'Anonymous' : createdBy;

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
                const _AvatarCircle(size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorLabel,
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
              const Text(
                'ASSIGNEE',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTertiary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              assignedTo != null
                  ? Row(
                      children: [
                        const Text(
                          'Assigned',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.slate800,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const _AvatarCircle(size: 28),
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
// Avatar circle (generic — no network image)
// =============================================================================

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({required this.size});

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
      child: Center(
        child: Icon(
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
  const _TimelineSection({required this.issue});

  final Issue issue;

  @override
  Widget build(BuildContext context) {
    final timeStr = timeago.format(issue.createdAt.toDate());
    final steps = <_TimelineStep>[];

    // Step 1: Issue Reported (always)
    steps.add(_TimelineStep(
      iconBg: AppColors.slate100,
      icon: Icons.error_outline,
      iconColor: AppColors.rose,
      title: 'Issue Reported',
      subtitle: '$timeStr by ${issue.anonymous ? 'Anonymous' : 'Author'}',
      isLast: false,
    ));

    // Step 2: Claimed (if assignee exists)
    if (issue.assignedTo != null) {
      steps.add(_TimelineStep(
        iconBg: AppColors.blue100,
        icon: Icons.person_outline,
        iconColor: AppColors.blue,
        title: 'Claimed',
        subtitle: 'by Assignee',
        isLast: false,
      ));
    }

    // Step 3: Resolved (if status=resolved)
    if (issue.status == IssueStatus.resolved) {
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
    if (issue.status == IssueStatus.disputed) {
      steps.add(_TimelineStep(
        iconBg: AppColors.rose,
        icon: Icons.warning_rounded,
        iconColor: Colors.white,
        title: 'Disputed',
        subtitle: 'by Reporter. "${issue.disputeReason ?? 'No reason given'}"',
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
  const _BottomActionBar({
    required this.issue,
    required this.currentUid,
    required this.onClaim,
    required this.onResolve,
    required this.onDispute,
    required this.onReact,
  });

  final Issue issue;
  final String? currentUid;
  final VoidCallback onClaim;
  final VoidCallback onResolve;
  final VoidCallback onDispute;
  final VoidCallback onReact;

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
    switch (issue.status) {
      case IssueStatus.open:
        return _ActionButton(
          label: 'Claim Issue (+50 pts)',
          backgroundColor: AppColors.orange,
          textColor: Colors.white,
          icon: Icons.arrow_forward_rounded,
          onTap: onClaim,
        );

      case IssueStatus.inProgress:
        if (issue.assignedTo == currentUid) {
          return _ActionButton(
            label: 'Mark Resolved',
            backgroundColor: AppColors.emerald,
            textColor: Colors.white,
            icon: Icons.check_rounded,
            onTap: onResolve,
          );
        } else {
          return const Center(
            child: Text(
              'Assigned to someone else',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
              ),
            ),
          );
        }

      case IssueStatus.resolved:
        if (issue.resolvedBy == currentUid) {
          // Resolved by current user — only show Props
          return _ActionButton(
            label: 'Props',
            backgroundColor: AppColors.emerald50,
            textColor: AppColors.emerald,
            icon: Icons.celebration_outlined,
            iconColor: AppColors.emerald,
            onTap: onReact,
          );
        } else {
          // Not the resolver — show both Dispute and Props
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
                  onTap: onDispute,
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
                  onTap: onReact,
                ),
              ),
            ],
          );
        }

      case IssueStatus.disputed:
      case IssueStatus.closed:
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
