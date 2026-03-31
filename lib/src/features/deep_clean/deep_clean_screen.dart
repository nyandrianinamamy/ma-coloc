import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../mock/mock_data.dart';
import '../../theme/app_theme.dart';

class DeepCleanScreen extends StatefulWidget {
  const DeepCleanScreen({super.key});

  @override
  State<DeepCleanScreen> createState() => _DeepCleanScreenState();
}

class _DeepCleanScreenState extends State<DeepCleanScreen> {
  // Local mutable copy of rooms
  late List<_RoomState> _rooms;

  @override
  void initState() {
    super.initState();
    _rooms = MockData.rooms
        .map((r) => _RoomState(
              id: r.id,
              name: r.name,
              status: r.status,
              assigneeId: r.assigneeId,
            ))
        .toList();
  }

  double get _progressPercent {
    if (_rooms.isEmpty) return 0;
    final cleanCount = _rooms.where((r) => r.status == 'clean').length;
    return cleanCount / _rooms.length;
  }

  void _claimRoom(String roomId) {
    setState(() {
      final idx = _rooms.indexWhere((r) => r.id == roomId);
      if (idx != -1) {
        _rooms[idx] = _rooms[idx].copyWith(
          status: 'assigned',
          assigneeId: MockData.currentUser.id,
        );
      }
    });
  }

  void _completeRoom(String roomId) {
    setState(() {
      final idx = _rooms.indexWhere((r) => r.id == roomId);
      if (idx != -1) {
        _rooms[idx] = _rooms[idx].copyWith(status: 'clean', assigneeId: null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final progressPercent = _progressPercent;
    final progressDisplay =
        '${(progressPercent * 100).round()}%';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DeepCleanHeader(
              progressDisplay: progressDisplay,
              progressPercent: progressPercent,
              onBack: () => context.pop(),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RoomAssignmentsHeader(totalRooms: _rooms.length),
                  const SizedBox(height: 14),
                  for (final room in _rooms) ...[
                    _RoomCard(
                      room: room,
                      onClaim: () => _claimRoom(room.id),
                      onComplete: () => _completeRoom(room.id),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Data model ──────────────────────────────────────────────────────────────

class _RoomState {
  const _RoomState({
    required this.id,
    required this.name,
    required this.status,
    this.assigneeId,
  });

  final String id;
  final String name;
  final String status; // 'dirty' | 'clean' | 'assigned'
  final String? assigneeId;

  _RoomState copyWith({String? status, String? assigneeId}) {
    return _RoomState(
      id: id,
      name: name,
      status: status ?? this.status,
      assigneeId: assigneeId ?? this.assigneeId,
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _DeepCleanHeader extends StatelessWidget {
  const _DeepCleanHeader({
    required this.progressDisplay,
    required this.progressPercent,
    required this.onBack,
  });

  final String progressDisplay;
  final double progressPercent;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.blue600, AppColors.indigo700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: back + title
              Row(
                children: [
                  GestureDetector(
                    onTap: onBack,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 22,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'March Deep Clean',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Progress card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'House Progress',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                progressDisplay,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Deadline',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Sunday 5PM',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        height: 12,
                        child: Stack(
                          children: [
                            // Background
                            Container(
                              color: Colors.black.withValues(alpha: 0.2),
                            ),
                            // Fill
                            FractionallySizedBox(
                              widthFactor: progressPercent.clamp(0.0, 1.0),
                              child: Container(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Room Assignments Header ──────────────────────────────────────────────────

class _RoomAssignmentsHeader extends StatelessWidget {
  const _RoomAssignmentsHeader({required this.totalRooms});

  final int totalRooms;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Room Assignments',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.slate800,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.blue100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${totalRooms * 100} pts total',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.blue600,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Room Card ────────────────────────────────────────────────────────────────

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.room,
    required this.onClaim,
    required this.onComplete,
  });

  final _RoomState room;
  final VoidCallback onClaim;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final currentUserId = MockData.currentUser.id;
    final isClean = room.status == 'clean';
    final isAssignedToMe =
        room.status == 'assigned' && room.assigneeId == currentUserId;
    final isAssignedToOther =
        room.status == 'assigned' && room.assigneeId != currentUserId;
    final isUnclaimed = room.status == 'dirty';

    final assignee = room.assigneeId != null
        ? MockData.userById(room.assigneeId!)
        : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '100 points',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
              // Status badge
              if (isClean)
                _StatusBadge(
                  label: 'Done',
                  bgColor: AppColors.emerald100,
                  textColor: AppColors.emerald,
                )
              else if (isAssignedToMe)
                _StatusBadgeWithAvatar(
                  label: 'Assigned',
                  avatarUrl: MockData.currentUser.avatarUrl,
                )
              else if (isAssignedToOther && assignee != null)
                _StatusBadgeWithAvatar(
                  label: 'Assigned',
                  avatarUrl: assignee.avatarUrl,
                )
              else
                _StatusBadge(
                  label: 'Unclaimed',
                  bgColor: AppColors.orange100,
                  textColor: AppColors.orange,
                ),
            ],
          ),
          if (!isClean) ...[
            const SizedBox(height: 14),
            if (isAssignedToMe)
              _ActionButton(
                label: 'Mark as Spotless',
                bgColor: AppColors.emerald,
                textColor: Colors.white,
                onTap: onComplete,
              )
            else if (isUnclaimed)
              _ActionButton(
                label: "I'll do it",
                bgColor: Colors.white,
                textColor: AppColors.slate700,
                borderColor: AppColors.slate200,
                onTap: onClaim,
              )
            else if (isAssignedToOther && assignee != null)
              _ActionButton(
                label: 'Assigned to ${assignee.name}',
                bgColor: AppColors.slate100,
                textColor: AppColors.slate400,
                onTap: null,
              ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  final String label;
  final Color bgColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _StatusBadgeWithAvatar extends StatelessWidget {
  const _StatusBadgeWithAvatar({
    required this.label,
    required this.avatarUrl,
  });

  final String label;
  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.blue100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundImage: NetworkImage(avatarUrl),
            backgroundColor: AppColors.slate200,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.blue600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.bgColor,
    required this.textColor,
    this.borderColor,
    required this.onTap,
  });

  final String label;
  final Color bgColor;
  final Color textColor;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: borderColor != null
              ? Border.all(color: borderColor!)
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
