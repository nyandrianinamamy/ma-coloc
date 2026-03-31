import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../mock/mock_data.dart';
import '../../../theme/app_theme.dart';

class IssueCard extends StatelessWidget {
  const IssueCard({super.key, required this.issue});

  final MockIssue issue;

  // Type-based placeholder color
  Color _typeColor() {
    switch (issue.type.toLowerCase()) {
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

  // Status badge config
  ({Color bg, Color border, Color text, Color icon, IconData iconData, String label}) _statusConfig() {
    switch (issue.status) {
      case 'open':
        return (
          bg: AppColors.orange50,
          border: AppColors.orange300,
          text: AppColors.orange,
          icon: AppColors.orange,
          iconData: Icons.radio_button_unchecked,
          label: 'OPEN',
        );
      case 'in-progress':
        return (
          bg: AppColors.blue50,
          border: AppColors.blue100,
          text: AppColors.blue600,
          icon: AppColors.blue600,
          iconData: Icons.autorenew,
          label: 'IN PROGRESS',
        );
      case 'resolved':
        return (
          bg: AppColors.emerald50,
          border: AppColors.emerald100,
          text: AppColors.emerald,
          icon: AppColors.emerald,
          iconData: Icons.check_circle_outline,
          label: 'RESOLVED',
        );
      case 'disputed':
        return (
          bg: AppColors.rose50,
          border: AppColors.rose100,
          text: AppColors.rose,
          icon: AppColors.rose,
          iconData: Icons.chat_bubble_outline,
          label: 'DISPUTED',
        );
      default:
        return (
          bg: AppColors.slate100,
          border: AppColors.slate200,
          text: AppColors.slate500,
          icon: AppColors.slate400,
          iconData: Icons.help_outline,
          label: issue.status.toUpperCase(),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _statusConfig();
    final typeColor = _typeColor();
    final assignee = issue.assigneeId != null
        ? MockData.userById(issue.assigneeId!)
        : null;
    final timeStr = timeago.format(issue.createdAt);

    return GestureDetector(
      onTap: () => context.push('/issues/${issue.id}'),
      child: Container(
        height: 128,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left 1/3: Photo thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
              child: SizedBox(
                width: 106,
                height: 128,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Placeholder colored by type (photoUrl is null in mock data)
                    issue.photoUrl != null
                        ? Image.network(
                            issue.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _TypePlaceholder(color: typeColor, type: issue.type),
                          )
                        : _TypePlaceholder(color: typeColor, type: issue.type),
                    // Type badge overlay (top-left)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xCC000000),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          issue.type.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Right 2/3: Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status badge
                    _StatusBadge(config: status),

                    // Title
                    Text(
                      issue.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.slate800,
                      ),
                    ),

                    // Bottom row: time + assignee/claim
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Clock + timeago
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 12,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 4),
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
                        // Assignee avatar or Claim button
                        assignee != null
                            ? _AssigneeAvatar(user: assignee)
                            : _ClaimButton(),
                      ],
                    ),
                  ],
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
// Type placeholder widget
// ---------------------------------------------------------------------------
class _TypePlaceholder extends StatelessWidget {
  const _TypePlaceholder({required this.color, required this.type});

  final Color color;
  final String type;

  IconData get _icon {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.12),
      child: Center(
        child: Icon(
          _icon,
          color: color.withValues(alpha: 0.6),
          size: 36,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status badge pill
// ---------------------------------------------------------------------------
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.config});

  final ({
    Color bg,
    Color border,
    Color text,
    Color icon,
    IconData iconData,
    String label
  }) config;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.iconData, size: 10, color: config.icon),
          const SizedBox(width: 3),
          Text(
            config.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: config.text,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Assignee avatar
// ---------------------------------------------------------------------------
class _AssigneeAvatar extends StatelessWidget {
  const _AssigneeAvatar({required this.user});

  final MockUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: ClipOval(
        child: Image.network(
          user.avatarUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.slate200,
            child: const Icon(Icons.person, size: 14, color: AppColors.slate400),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Claim button
// ---------------------------------------------------------------------------
class _ClaimButton extends StatelessWidget {
  const _ClaimButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.emerald,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Claim',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
