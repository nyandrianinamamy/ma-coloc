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
import '../../providers/member_provider.dart';
import '../../theme/app_theme.dart';

class IssueDetailScreen extends ConsumerWidget {
  const IssueDetailScreen({super.key, required this.issueId});

  final String issueId;

  ({Color color, String label}) _statusConfig(IssueStatus status) {
    switch (status) {
      case IssueStatus.open:
        return (color: AppColors.orange, label: 'OPEN');
      case IssueStatus.inProgress:
        return (color: AppColors.blue, label: 'IN PROGRESS');
      case IssueStatus.resolved:
        return (color: AppColors.emerald, label: 'RESOLVED');
      case IssueStatus.disputed:
        return (color: AppColors.rose, label: 'DISPUTED');
      case IssueStatus.closed:
        return (color: AppColors.slate400, label: 'CLOSED');
    }
  }

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
    final isPlaceholder = kDebugMode && DefaultFirebaseOptions.isPlaceholder;

    final String houseId;
    final String? currentUid;
    Issue? issue;

    if (isPlaceholder) {
      houseId = 'placeholder';
      currentUid = null;
      issue = _mockIssueById(issueId);
    } else {
      final houseIdValue = ref.watch(currentHouseIdProvider).valueOrNull;
      currentUid = ref.watch(authStateProvider).valueOrNull?.uid;

      if (houseIdValue == null) {
        return Scaffold(
          backgroundColor: const Color(0xFFFAFAF7),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      houseId = houseIdValue;
    }

    if (isPlaceholder) {
      return _buildDetail(context, ref,
          issue: issue,
          houseId: houseId,
          currentUid: currentUid,
          isPlaceholder: true);
    }

    final issueAsync = ref.watch(issueDetailProvider((houseId, issueId)));

    return issueAsync.when(
      loading: () => Scaffold(
        backgroundColor: const Color(0xFFFAFAF7),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: const Color(0xFFFAFAF7),
        body: Center(child: Text('Error: $e')),
      ),
      data: (loadedIssue) => _buildDetail(context, ref,
          issue: loadedIssue,
          houseId: houseId,
          currentUid: currentUid,
          isPlaceholder: false),
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
        backgroundColor: const Color(0xFFFAFAF7),
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

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Sticky white header ──
              SliverToBoxAdapter(
                child: _StickyHeader(
                  issue: issue,
                  status: status,
                  onBack: () => context.pop(),
                ),
              ),

              // ── Content ──
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Photo
                    if (issue.photoUrl != null && issue.photoUrl!.isNotEmpty)
                      _PhotoCard(photoUrl: issue.photoUrl!),
                    if (issue.photoUrl != null && issue.photoUrl!.isNotEmpty)
                      const SizedBox(height: 24),

                    // Author / Assignee
                    _MetaCard(
                      issue: issue,
                      houseId: houseId,
                      isPlaceholder: isPlaceholder,
                    ),
                    const SizedBox(height: 24),

                    // Description
                    if (issue.description != null &&
                        issue.description!.isNotEmpty) ...[
                      Text(
                        'DESCRIPTION',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slate800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.slate100),
                        ),
                        child: Text(
                          issue.description!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.slate500,
                            height: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Timeline
                    Text(
                      'TIMELINE',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.slate800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _TimelineSection(
                      issue: issue,
                      houseId: houseId,
                      isPlaceholder: isPlaceholder,
                    ),
                  ]),
                ),
              ),
            ],
          ),

          // ── Bottom action bar ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomActionBar(
              issue: issue,
              currentUid: currentUid,
              onClaim: isPlaceholder
                  ? () {}
                  : () => ref
                      .read(issueActionsProvider.notifier)
                      .claim(houseId: houseId, issueId: issueId),
              onResolve: isPlaceholder
                  ? () {}
                  : () => _showResolveSheet(context, ref,
                      houseId: houseId, issueId: issueId),
              onDispute: isPlaceholder
                  ? () {}
                  : () => _showDisputeDialog(context, ref,
                      houseId: houseId, issueId: issueId, issue: issue),
              onReact: isPlaceholder
                  ? () {}
                  : () => ref.read(issueActionsProvider.notifier).react(
                      houseId: houseId, issueId: issueId, emoji: '👏'),
            ),
          ),
        ],
      ),
    );
  }

  void _showResolveSheet(BuildContext context, WidgetRef ref,
      {required String houseId, required String issueId}) {
    final noteController = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 24, 16, 16 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resolution Note (optional)',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate800)),
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
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  final house = ref.read(currentHouseProvider).valueOrNull;
                  final windowHours =
                      house?.settings.disputeWindowHours ?? 48;
                  ref.read(issueActionsProvider.notifier).resolve(
                        houseId: houseId,
                        issueId: issueId,
                        note: noteController.text.trim().isEmpty
                            ? null
                            : noteController.text.trim(),
                        disputeWindowHours: windowHours,
                      );
                },
                child: Text('Confirm Resolution',
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDisputeDialog(BuildContext context, WidgetRef ref,
      {required String houseId,
      required String issueId,
      required Issue issue}) {
    final reasonController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
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
              child: const Text('Cancel')),
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
            child:
                const Text('Dispute', style: TextStyle(color: AppColors.rose)),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Sticky Header (white bg, shadow)
// =============================================================================

class _StickyHeader extends StatelessWidget {
  const _StickyHeader({
    required this.issue,
    required this.status,
    required this.onBack,
  });

  final Issue issue;
  final ({Color color, String label}) status;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(24, topPadding + 12, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top nav row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CircleButton(
                onTap: onBack,
                child: const Icon(Icons.chevron_left,
                    size: 24, color: AppColors.slate800),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  issue.type.name.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              _CircleButton(
                onTap: () {},
                child: const Icon(Icons.more_horiz,
                    size: 24, color: AppColors.slate800),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Status row
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: status.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                status.label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate500,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Title
          Text(
            issue.title ?? 'Untitled Issue',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.slate800,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.slate100,
          shape: BoxShape.circle,
        ),
        child: Center(child: child),
      ),
    );
  }
}

// =============================================================================
// Photo Card
// =============================================================================

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({required this.photoUrl});

  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          color: AppColors.slate200,
          child: Image.network(
            photoUrl,
            fit: BoxFit.contain,
            width: double.infinity,
            errorBuilder: (_, __, ___) => const SizedBox(
              height: 200,
              child: Center(
                child: Icon(Icons.broken_image_outlined,
                    size: 48, color: AppColors.slate400),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Meta Card (author + assignee)
// =============================================================================

class _MetaCard extends ConsumerWidget {
  const _MetaCard({
    required this.issue,
    required this.houseId,
    required this.isPlaceholder,
  });

  final Issue issue;
  final String houseId;
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeStr = timeago.format(issue.createdAt.toDate());
    final authorName = issue.anonymous
        ? 'Anonymous'
        : isPlaceholder
            ? issue.createdBy
            : ref.watch(memberDisplayNameProvider((houseId, issue.createdBy)));
    final assigneeName = issue.assignedTo != null && !isPlaceholder
        ? ref.watch(memberDisplayNameProvider((houseId, issue.assignedTo!)))
        : issue.assignedTo;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Row(
        children: [
          // Author
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.slate100,
                    border: Border.all(color: AppColors.slate200, width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(Icons.person, size: 22, color: AppColors.slate400),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorName,
                        style: GoogleFonts.inter(
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
                          const Icon(Icons.access_time,
                              size: 12, color: AppColors.slate500),
                          const SizedBox(width: 4),
                          Text(
                            timeStr,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.slate500,
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

          // Assignee
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'ASSIGNEE',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate400,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              if (assigneeName != null)
                Row(
                  children: [
                    Text(
                      assigneeName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.slate100,
                      ),
                      child: const Icon(Icons.person,
                          size: 14, color: AppColors.slate400),
                    ),
                  ],
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.orange50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Unassigned',
                    style: GoogleFonts.inter(
                      fontSize: 12,
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
// Timeline
// =============================================================================

class _TimelineSection extends ConsumerWidget {
  const _TimelineSection({
    required this.issue,
    required this.houseId,
    required this.isPlaceholder,
  });

  final Issue issue;
  final String houseId;
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeStr = timeago.format(issue.createdAt.toDate());
    final authorName = issue.anonymous
        ? 'Anonymous'
        : isPlaceholder
            ? 'Author'
            : ref.watch(memberDisplayNameProvider((houseId, issue.createdBy)));

    final assigneeName = issue.assignedTo != null && !isPlaceholder
        ? ref.watch(memberDisplayNameProvider((houseId, issue.assignedTo!)))
        : 'Assignee';

    return Column(
      children: [
        // Created
        _TimelineStep(
          bgColor: AppColors.slate100,
          icon: Icons.error_outline,
          iconColor: AppColors.slate500,
          title: 'Issue Reported',
          subtitle: '$timeStr by $authorName',
          isLast: issue.assignedTo == null &&
              issue.status != IssueStatus.resolved &&
              issue.status != IssueStatus.disputed &&
              issue.status != IssueStatus.closed,
        ),

        // Claimed
        if (issue.assignedTo != null)
          _TimelineStep(
            bgColor: AppColors.blue100,
            icon: Icons.person_outline,
            iconColor: AppColors.blue,
            title: 'Claimed',
            subtitle: 'by $assigneeName',
            isLast: issue.status != IssueStatus.resolved &&
                issue.status != IssueStatus.disputed &&
                issue.status != IssueStatus.closed,
          ),

        // Resolved
        if (issue.status == IssueStatus.resolved)
          _TimelineStep(
            bgColor: AppColors.emerald,
            icon: Icons.check,
            iconColor: Colors.white,
            title: 'Resolved',
            subtitle: 'Pending 24h dispute window',
            isLast: true,
          ),

        // Disputed
        if (issue.status == IssueStatus.disputed)
          _TimelineStep(
            bgColor: AppColors.rose,
            icon: Icons.warning_rounded,
            iconColor: Colors.white,
            title: 'Disputed',
            subtitle: issue.disputeReason ?? 'No reason given',
            isLast: true,
          ),

        // Closed
        if (issue.status == IssueStatus.closed) ...[
          if (issue.resolvedBy != null)
            _TimelineStep(
              bgColor: AppColors.emerald,
              icon: Icons.check,
              iconColor: Colors.white,
              title: 'Resolved',
              subtitle: 'by resolver',
              isLast: false,
            ),
          _TimelineStep(
            bgColor: AppColors.slate400,
            icon: Icons.lock_outline,
            iconColor: Colors.white,
            title: 'Closed',
            subtitle: 'Auto-closed after dispute window',
            isLast: true,
          ),
        ],
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.bgColor,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isLast,
  });

  final Color bgColor;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFFFAFAF7), width: 4),
                  ),
                  child: Icon(icon, size: 16, color: iconColor),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.slate200,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate500,
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
// Bottom Action Bar
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
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        border: const Border(top: BorderSide(color: AppColors.slate100)),
      ),
      child: _buildActions(),
    );
  }

  Widget _buildActions() {
    switch (issue.status) {
      case IssueStatus.open:
        return _ActionButton(
          label: 'Claim Issue (+${issue.points} pts)',
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
            icon: Icons.check_circle_outline,
            onTap: onResolve,
          );
        }
        return Center(
          child: Text(
            'Assigned to someone else',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.slate400,
            ),
          ),
        );

      case IssueStatus.resolved:
        if (issue.resolvedBy == currentUid) {
          return _ActionButton(
            label: 'Props',
            backgroundColor: AppColors.emerald50,
            textColor: AppColors.emerald,
            icon: Icons.celebration_outlined,
            onTap: onReact,
          );
        }
        return Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Dispute',
                backgroundColor: Colors.white,
                textColor: AppColors.slate800,
                borderColor: AppColors.slate200,
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
                borderColor: AppColors.emerald100,
                icon: Icons.celebration_outlined,
                onTap: onReact,
              ),
            ),
          ],
        );

      case IssueStatus.disputed:
      case IssueStatus.closed:
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No actions available',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.slate400,
              ),
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
        height: 56,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: borderColor != null
              ? Border.all(color: borderColor!, width: 2)
              : null,
          boxShadow: borderColor == null
              ? [
                  BoxShadow(
                    color: backgroundColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 20, color: iconColor ?? textColor),
          ],
        ),
      ),
    );
  }
}
