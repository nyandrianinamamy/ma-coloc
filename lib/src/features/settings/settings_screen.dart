import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../firebase_options.dart';
import '../../mock/mock_data.dart';
import '../../models/member.dart';
import '../../providers/auth_provider.dart';
import '../../providers/house_provider.dart';
import '../../providers/member_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    // Placeholder mode: debug build with placeholder Firebase config
    if (kDebugMode && DefaultFirebaseOptions.isPlaceholder) {
      return const _MockSettingsScreen();
    }

    final houseIdAsync = ref.watch(currentHouseIdProvider);
    final houseId = houseIdAsync.valueOrNull;

    if (houseIdAsync.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (houseId == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: Text('No house found.')),
      );
    }

    final houseAsync = ref.watch(currentHouseProvider);
    final membersAsync = ref.watch(membersStreamProvider(houseId));
    final authAsync = ref.watch(authStateProvider);
    final uid = authAsync.valueOrNull?.uid;

    return membersAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Error: $e')),
      ),
      data: (members) {
        final currentMember = members.where((m) => m.uid == uid).firstOrNull;
        final isAdmin = currentMember?.role == MemberRole.admin;
        final house = houseAsync.valueOrNull;
        final houseName = house?.name ?? 'My House';
        final memberCount = members.length;
        final inviteCode = house?.inviteCode ?? '';
        final notificationsEnabled =
            currentMember?.notificationsEnabled ?? true;

        return _LiveSettingsScreen(
          houseId: houseId,
          houseName: houseName,
          memberCount: memberCount,
          inviteCode: inviteCode,
          members: members,
          currentMember: currentMember,
          isAdmin: isAdmin,
          notificationsEnabled: notificationsEnabled,
        );
      },
    );
  }
}

// ─── Live Settings Screen ────────────────────────────────────────────────────

class _LiveSettingsScreen extends ConsumerStatefulWidget {
  const _LiveSettingsScreen({
    required this.houseId,
    required this.houseName,
    required this.memberCount,
    required this.inviteCode,
    required this.members,
    required this.currentMember,
    required this.isAdmin,
    required this.notificationsEnabled,
  });

  final String houseId;
  final String houseName;
  final int memberCount;
  final String inviteCode;
  final List<Member> members;
  final Member? currentMember;
  final bool isAdmin;
  final bool notificationsEnabled;

  @override
  ConsumerState<_LiveSettingsScreen> createState() =>
      _LiveSettingsScreenState();
}

class _LiveSettingsScreenState extends ConsumerState<_LiveSettingsScreen> {
  bool _isEditingName = false;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.houseName);
  }

  @override
  void didUpdateWidget(_LiveSettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditingName && oldWidget.houseName != widget.houseName) {
      _nameController.text = widget.houseName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitHouseName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;
    setState(() => _isEditingName = false);
    await ref.read(settingsActionsProvider.notifier).updateHouseName(
          houseId: widget.houseId,
          name: newName,
        );
  }

  Future<void> _copyInviteCode() async {
    await Clipboard.setData(ClipboardData(text: widget.inviteCode));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied!')),
      );
    }
  }

  void _shareInviteCode() {
    Share.share(
        'Join my house on MaColoc! Invite code: ${widget.inviteCode}');
  }

  Future<void> _showMemberOptions(Member member) async {
    if (!widget.isAdmin) return;
    // Don't show options for self
    if (member.uid == widget.currentMember?.uid) return;

    final isTargetAdmin = member.role == MemberRole.admin;

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.slate200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  member.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(
                  isTargetAdmin
                      ? Icons.person_outline_rounded
                      : Icons.admin_panel_settings_outlined,
                  color: AppColors.slate700,
                ),
                title: Text(
                  isTargetAdmin ? 'Make Member' : 'Make Admin',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate800,
                  ),
                ),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await ref
                      .read(settingsActionsProvider.notifier)
                      .updateMemberRole(
                        houseId: widget.houseId,
                        targetUid: member.uid,
                        newRole: isTargetAdmin ? 'member' : 'admin',
                      );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.person_remove_outlined,
                  color: AppColors.rose,
                ),
                title: const Text(
                  'Remove from house',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.rose,
                  ),
                ),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      title: const Text('Remove member?'),
                      content: Text(
                          'Remove ${member.displayName} from the house?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dCtx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(dCtx).pop(true),
                          child: const Text(
                            'Remove',
                            style: TextStyle(color: AppColors.rose),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await ref
                        .read(settingsActionsProvider.notifier)
                        .removeMember(
                          houseId: widget.houseId,
                          targetUid: member.uid,
                        );
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _leaveHouse() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Leave house?'),
        content:
            Text('Are you sure you want to leave ${widget.houseName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(true),
            child: const Text(
              'Leave',
              style: TextStyle(color: AppColors.rose),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref
          .read(houseActionsProvider.notifier)
          .leaveHouse(widget.houseId);
      if (mounted) context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SettingsHeader(),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('THE HOUSE'),
                  const SizedBox(height: 12),
                  _LiveHouseInfoCard(
                    houseId: widget.houseId,
                    houseName: widget.houseName,
                    memberCount: widget.memberCount,
                    inviteCode: widget.inviteCode,
                    isAdmin: widget.isAdmin,
                    isEditingName: _isEditingName,
                    nameController: _nameController,
                    onEditTap: () =>
                        setState(() => _isEditingName = true),
                    onNameSubmit: _submitHouseName,
                    onCopyCode: _copyInviteCode,
                    onShareCode: _shareInviteCode,
                  ),
                  const SizedBox(height: 28),
                  _SectionLabel('PREFERENCES'),
                  const SizedBox(height: 12),
                  _PreferencesCard(
                    notificationsEnabled: widget.notificationsEnabled,
                    onNotificationsChanged: (val) async {
                      await ref
                          .read(settingsActionsProvider.notifier)
                          .toggleNotifications(
                            houseId: widget.houseId,
                            enabled: val,
                          );
                    },
                  ),
                  const SizedBox(height: 28),
                  _LiveMembersSection(
                    members: widget.members,
                    currentMember: widget.currentMember,
                    isAdmin: widget.isAdmin,
                    onMemberLongPress: _showMemberOptions,
                  ),
                  if (widget.isAdmin) ...[
                    const SizedBox(height: 28),
                    GestureDetector(
                      onTap: () => context.push('/data-privacy'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.shield_outlined,
                                size: 20, color: AppColors.slate700),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Data & Privacy',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.slate700,
                                ),
                              ),
                            ),
                            Icon(Icons.chevron_right,
                                size: 20, color: AppColors.slate400),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  _DangerZone(
                    isDemo: ref.watch(currentHouseProvider).valueOrNull?.isDemo ?? false,
                    onExitDemo: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Exit Demo'),
                          content: const Text(
                              'This will delete the demo data and sign you out.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Exit Demo'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && context.mounted) {
                        showDialog<void>(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const PopScope(
                            canPop: false,
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        );
                        // Capture refs before any await — the widget may be
                        // disposed mid-flight when the router redirects.
                        final houseId =
                            ref.read(currentHouseIdProvider).valueOrNull;
                        final houseActions =
                            ref.read(houseActionsProvider.notifier);
                        final authNotifier =
                            ref.read(authNotifierProvider.notifier);
                        if (houseId != null) {
                          await houseActions.cleanupDemoHouse(houseId);
                        }
                        await authNotifier.signOut();
                      }
                    },
                    onLeave: _leaveHouse,
                    onSignOut: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Sign Out'),
                          content: const Text('Are you sure you want to sign out?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Sign Out'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && context.mounted) {
                        await ref.read(authNotifierProvider.notifier).signOut();
                      }
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Mock Settings Screen ────────────────────────────────────────────────────

class _MockSettingsScreen extends StatefulWidget {
  const _MockSettingsScreen();

  @override
  State<_MockSettingsScreen> createState() => _MockSettingsScreenState();
}

class _MockSettingsScreenState extends State<_MockSettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SettingsHeader(),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('THE HOUSE'),
                  const SizedBox(height: 12),
                  _MockHouseInfoCard(),
                  const SizedBox(height: 28),
                  _SectionLabel('PREFERENCES'),
                  const SizedBox(height: 12),
                  _PreferencesCard(
                    notificationsEnabled: _notificationsEnabled,
                    onNotificationsChanged: (val) =>
                        setState(() => _notificationsEnabled = val),
                  ),
                  const SizedBox(height: 28),
                  _MockMembersSection(),
                  const SizedBox(height: 28),
                  _DangerZone(onLeave: () {}, onSignOut: () {}),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ─────────────────────────────────────────────────────────────────

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.slate100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    size: 24,
                    color: AppColors.slate700,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'House Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section Label ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: AppColors.slate400,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ─── Live House Info Card ────────────────────────────────────────────────────

class _LiveHouseInfoCard extends StatelessWidget {
  const _LiveHouseInfoCard({
    required this.houseId,
    required this.houseName,
    required this.memberCount,
    required this.inviteCode,
    required this.isAdmin,
    required this.isEditingName,
    required this.nameController,
    required this.onEditTap,
    required this.onNameSubmit,
    required this.onCopyCode,
    required this.onShareCode,
  });

  final String houseId;
  final String houseName;
  final int memberCount;
  final String inviteCode;
  final bool isAdmin;
  final bool isEditingName;
  final TextEditingController nameController;
  final VoidCallback onEditTap;
  final VoidCallback onNameSubmit;
  final VoidCallback onCopyCode;
  final VoidCallback onShareCode;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // House info row
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.slate100),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.emerald100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.home_rounded,
                  color: AppColors.emerald,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isEditingName)
                      TextField(
                        controller: nameController,
                        autofocus: true,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate800,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => onNameSubmit(),
                        textInputAction: TextInputAction.done,
                      )
                    else
                      Text(
                        houseName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate800,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      '$memberCount Member${memberCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isAdmin)
                GestureDetector(
                  onTap: isEditingName ? onNameSubmit : onEditTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.emerald,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isEditingName ? 'Save' : 'Edit',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Invite code section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.slate100,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'INVITE CODE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate400,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Text(
                  inviteCode.isEmpty ? '--------' : inviteCode,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate800,
                    letterSpacing: 4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Copy button
                  GestureDetector(
                    onTap: onCopyCode,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: const Icon(
                        Icons.copy_rounded,
                        size: 20,
                        color: AppColors.slate500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Share button
                  GestureDetector(
                    onTap: onShareCode,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.emerald,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.share_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Share',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Mock House Info Card ────────────────────────────────────────────────────

class _MockHouseInfoCard extends StatelessWidget {
  const _MockHouseInfoCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // House info row
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.slate100),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.emerald100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.home_rounded,
                  color: AppColors.emerald,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'The Treehouse',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '6 Members',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.emerald,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Invite code section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.slate100,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'INVITE CODE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate400,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: const Text(
                  'MAC-8X2F',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate800,
                    letterSpacing: 4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Preferences Card ────────────────────────────────────────────────────────

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard({
    required this.notificationsEnabled,
    required this.onNotificationsChanged,
  });

  final bool notificationsEnabled;
  final ValueChanged<bool> onNotificationsChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Column(
        children: [
          // Notifications row
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.blue100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    size: 20,
                    color: AppColors.blue,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate800,
                    ),
                  ),
                ),
                Switch(
                  value: notificationsEnabled,
                  onChanged: onNotificationsChanged,
                  activeThumbColor: AppColors.emerald,
                  trackColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.emerald100;
                    }
                    return AppColors.slate200;
                  }),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: AppColors.slate100),
          // Manage Rooms row
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.orange100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.people_outline_rounded,
                    size: 20,
                    color: AppColors.orange,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Manage Rooms',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate800,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: AppColors.slate400,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Live Members Section ────────────────────────────────────────────────────

class _LiveMembersSection extends StatelessWidget {
  const _LiveMembersSection({
    required this.members,
    required this.currentMember,
    required this.isAdmin,
    required this.onMemberLongPress,
  });

  final List<Member> members;
  final Member? currentMember;
  final bool isAdmin;
  final Future<void> Function(Member) onMemberLongPress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'MEMBERS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate400,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Text(
              '${members.length} Total',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.emerald,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.slate100),
          ),
          child: Column(
            children: [
              for (int i = 0; i < members.length; i++) ...[
                _LiveMemberRow(
                  member: members[i],
                  isSelf: members[i].uid == currentMember?.uid,
                  canLongPress: isAdmin &&
                      members[i].uid != currentMember?.uid,
                  onLongPress: () => onMemberLongPress(members[i]),
                ),
                if (i < members.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.slate100,
                    indent: 20,
                    endIndent: 20,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LiveMemberRow extends StatelessWidget {
  const _LiveMemberRow({
    required this.member,
    required this.isSelf,
    required this.canLongPress,
    required this.onLongPress,
  });

  final Member member;
  final bool isSelf;
  final bool canLongPress;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final isAdmin = member.role == MemberRole.admin;

    return GestureDetector(
      onLongPress: canLongPress ? onLongPress : null,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.slate100,
              backgroundImage: member.avatarUrl != null
                  ? NetworkImage(member.avatarUrl!)
                  : null,
              child: member.avatarUrl == null
                  ? const Icon(Icons.person,
                      size: 20, color: AppColors.slate400)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                isSelf
                    ? '${member.displayName} (You)'
                    : member.displayName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate800,
                ),
              ),
            ),
            if (isAdmin)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emerald100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'ADMIN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.emerald,
                    letterSpacing: 0.8,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'MEMBER',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate500,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Mock Members Section ────────────────────────────────────────────────────

class _MockMembersSection extends StatelessWidget {
  const _MockMembersSection();

  @override
  Widget build(BuildContext context) {
    final members = MockData.users.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'MEMBERS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate400,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const Text(
              'View All',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.emerald,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.slate100),
          ),
          child: Column(
            children: [
              for (int i = 0; i < members.length; i++) ...[
                _MockMemberRow(
                  user: members[i],
                  isAdmin: members[i].id == 'u1',
                ),
                if (i < members.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.slate100,
                    indent: 20,
                    endIndent: 20,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MockMemberRow extends StatelessWidget {
  const _MockMemberRow({required this.user, required this.isAdmin});

  final MockUser user;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(user.avatarUrl),
            backgroundColor: AppColors.slate100,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              user.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.slate800,
              ),
            ),
          ),
          if (isAdmin)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.emerald100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'ADMIN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.emerald,
                  letterSpacing: 0.8,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Danger Zone ─────────────────────────────────────────────────────────────

class _DangerZone extends StatelessWidget {
  const _DangerZone({
    required this.onLeave,
    required this.onSignOut,
    this.isDemo = false,
    this.onExitDemo,
  });

  final VoidCallback onLeave;
  final VoidCallback onSignOut;
  final bool isDemo;
  final VoidCallback? onExitDemo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isDemo && onExitDemo != null) ...[
          GestureDetector(
            onTap: onExitDemo,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.explore_off_rounded, size: 20, color: Color(0xFFB45309)),
                  SizedBox(width: 10),
                  Text(
                    'Exit Demo',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        GestureDetector(
          onTap: onLeave,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.rose50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.rose100),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout_rounded,
                  size: 20,
                  color: AppColors.rose,
                ),
                SizedBox(width: 10),
                Text(
                  'Leave House',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.rose,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onSignOut,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.slate100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.slate200),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.power_settings_new_rounded,
                  size: 20,
                  color: AppColors.slate700,
                ),
                SizedBox(width: 10),
                Text(
                  'Sign Out',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
