import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../firebase_options.dart';
import '../../mock/mock_data.dart';
import '../../models/deep_clean.dart';
import '../../providers/auth_provider.dart';
import '../../providers/deep_clean_provider.dart';
import '../../providers/house_provider.dart';
import '../../theme/app_theme.dart';

class DeepCleanScreen extends ConsumerStatefulWidget {
  const DeepCleanScreen({super.key});

  @override
  ConsumerState<DeepCleanScreen> createState() => _DeepCleanScreenState();
}

class _DeepCleanScreenState extends ConsumerState<DeepCleanScreen> {
  // Mock state for placeholder mode
  late List<_MockRoom> _mockRooms;

  @override
  void initState() {
    super.initState();
    _mockRooms = MockData.rooms
        .map((r) => _MockRoom(
              id: r.id,
              name: r.name,
              status: r.status,
              assigneeId: r.assigneeId,
            ))
        .toList();
  }

  double get _mockProgressPercent {
    if (_mockRooms.isEmpty) return 0;
    final cleanCount = _mockRooms.where((r) => r.status == 'clean').length;
    return cleanCount / _mockRooms.length;
  }

  void _mockClaimRoom(String roomId) {
    setState(() {
      final idx = _mockRooms.indexWhere((r) => r.id == roomId);
      if (idx != -1) {
        _mockRooms[idx] = _mockRooms[idx].copyWith(
          status: 'assigned',
          assigneeId: MockData.currentUser.id,
        );
      }
    });
  }

  void _mockCompleteRoom(String roomId) {
    setState(() {
      final idx = _mockRooms.indexWhere((r) => r.id == roomId);
      if (idx != -1) {
        _mockRooms[idx] =
            _mockRooms[idx].copyWith(status: 'clean', assigneeId: null);
      }
    });
  }

  Widget get _loadingWidget => Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );

  Widget get _errorWidget => Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: Text('Something went wrong')),
      );

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = kDebugMode && DefaultFirebaseOptions.isPlaceholder;
    if (isPlaceholder) return _buildMockScreen(context);

    final houseIdAsync = ref.watch(currentHouseIdProvider);
    final houseId = houseIdAsync.valueOrNull;
    if (houseId == null) return _loadingWidget;

    final deepCleanAsync = ref.watch(currentDeepCleanProvider(houseId));
    final currentUid = ref.watch(authStateProvider).valueOrNull?.uid;

    return deepCleanAsync.when(
      loading: () => _loadingWidget,
      error: (e, _) => _errorWidget,
      data: (deepClean) {
        if (deepClean == null) return _buildEmptyState(context);
        return _buildLiveScreen(
          context,
          deepClean: deepClean,
          houseId: houseId,
          currentUid: currentUid,
        );
      },
    );
  }

  // ── Mock / placeholder screen ───────────────────────────────────────────────

  Widget _buildMockScreen(BuildContext context) {
    final progressPercent = _mockProgressPercent;
    final progressDisplay = '${(progressPercent * 100).round()}%';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DeepCleanHeader(
              title: 'March Deep Clean',
              progressDisplay: progressDisplay,
              progressPercent: progressPercent,
              deadlineLabel: 'Sunday 5PM',
              onBack: () => context.pop(),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RoomAssignmentsHeader(totalRooms: _mockRooms.length),
                  const SizedBox(height: 14),
                  for (final room in _mockRooms) ...[
                    _MockRoomCard(
                      room: room,
                      onClaim: () => _mockClaimRoom(room.id),
                      onComplete: () => _mockCompleteRoom(room.id),
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

  // ── Live Firestore screen ───────────────────────────────────────────────────

  Widget _buildLiveScreen(
    BuildContext context, {
    required DeepClean deepClean,
    required String houseId,
    required String? currentUid,
  }) {
    final monthDate = DateTime.parse('${deepClean.month}-01');
    final title = '${DateFormat.MMMM().format(monthDate)} Deep Clean';
    final deadlineLabel =
        DateFormat('EEEE h:mma').format(deepClean.volunteerDeadline.toDate());

    final totalRooms = deepClean.assignments.length;
    final completedCount =
        deepClean.assignments.values.where((a) => a.completed).length;
    final progressPercent =
        totalRooms == 0 ? 0.0 : completedCount / totalRooms;
    final progressDisplay = '${(progressPercent * 100).round()}%';

    final entries = deepClean.assignments.entries.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DeepCleanHeader(
              title: title,
              progressDisplay: progressDisplay,
              progressPercent: progressPercent,
              deadlineLabel: deadlineLabel,
              onBack: () => context.pop(),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RoomAssignmentsHeader(totalRooms: totalRooms),
                  const SizedBox(height: 14),
                  for (final entry in entries) ...[
                    _LiveRoomCard(
                      roomName: entry.key,
                      assignment: entry.value,
                      currentUid: currentUid,
                      onClaim: () {
                        ref
                            .read(deepCleanActionsProvider.notifier)
                            .claimRoom(
                              houseId: houseId,
                              cleanId: deepClean.id,
                              roomName: entry.key,
                            );
                      },
                      onComplete: () {
                        ref
                            .read(deepCleanActionsProvider.notifier)
                            .completeRoom(
                              houseId: houseId,
                              cleanId: deepClean.id,
                              roomName: entry.key,
                            );
                      },
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

  // ── Empty state ─────────────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context) {
    final now = DateTime.now();
    final title = '${DateFormat.MMMM().format(now)} Deep Clean';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DeepCleanHeader(
              title: title,
              progressDisplay: '0%',
              progressPercent: 0.0,
              deadlineLabel: 'Not scheduled',
              onBack: () => context.pop(),
            ),
            const SizedBox(height: 80),
            const Center(
              child: Text(
                'No deep clean scheduled this month',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.slate500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Mock room data model (placeholder mode only) ─────────────────────────────

class _MockRoom {
  const _MockRoom({
    required this.id,
    required this.name,
    required this.status,
    this.assigneeId,
  });

  final String id;
  final String name;
  final String status; // 'dirty' | 'clean' | 'assigned'
  final String? assigneeId;

  _MockRoom copyWith({String? status, String? assigneeId}) {
    return _MockRoom(
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
    required this.title,
    required this.progressDisplay,
    required this.progressPercent,
    required this.deadlineLabel,
    required this.onBack,
  });

  final String title;
  final String progressDisplay;
  final double progressPercent;
  final String deadlineLabel;
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
                  Text(
                    title,
                    style: const TextStyle(
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
                              child: Text(
                                deadlineLabel,
                                style: const TextStyle(
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

// ─── Live Room Card (Firestore-backed) ────────────────────────────────────────

class _LiveRoomCard extends StatelessWidget {
  const _LiveRoomCard({
    required this.roomName,
    required this.assignment,
    required this.currentUid,
    required this.onClaim,
    required this.onComplete,
  });

  final String roomName;
  final RoomAssignment assignment;
  final String? currentUid;
  final VoidCallback onClaim;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final isCompleted = assignment.completed;
    final isAssignedToMe =
        assignment.uid != null && assignment.uid == currentUid;
    final isUnclaimed = assignment.uid == null;

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
                      roomName,
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
              if (isCompleted)
                _StatusBadge(
                  label: 'Done',
                  bgColor: AppColors.emerald100,
                  textColor: AppColors.emerald,
                )
              else if (isUnclaimed)
                _StatusBadge(
                  label: 'Unclaimed',
                  bgColor: AppColors.orange100,
                  textColor: AppColors.orange,
                )
              else
                _StatusBadge(
                  label: 'Assigned',
                  bgColor: AppColors.blue100,
                  textColor: AppColors.blue600,
                ),
            ],
          ),
          if (!isCompleted) ...[
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
            else
              _ActionButton(
                label: 'Assigned to someone',
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

// ─── Mock Room Card (placeholder mode only) ───────────────────────────────────

class _MockRoomCard extends StatelessWidget {
  const _MockRoomCard({
    required this.room,
    required this.onClaim,
    required this.onComplete,
  });

  final _MockRoom room;
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

    final assignee =
        room.assigneeId != null ? MockData.userById(room.assigneeId!) : null;

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

// ─── Shared visual widgets ────────────────────────────────────────────────────

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
          border: borderColor != null ? Border.all(color: borderColor!) : null,
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
