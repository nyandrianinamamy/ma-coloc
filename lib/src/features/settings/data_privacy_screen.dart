import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/data_management_provider.dart';
import '../../providers/house_provider.dart';
import '../../theme/app_theme.dart';
import 'widgets/typed_confirm_dialog.dart';

class DataPrivacyScreen extends ConsumerStatefulWidget {
  const DataPrivacyScreen({super.key});

  @override
  ConsumerState<DataPrivacyScreen> createState() => _DataPrivacyScreenState();
}

class _DataPrivacyScreenState extends ConsumerState<DataPrivacyScreen> {
  @override
  Widget build(BuildContext context) {
    final houseIdAsync = ref.watch(currentHouseIdProvider);
    final houseId = houseIdAsync.valueOrNull;

    // Listen for errors from dataManagementProvider
    ref.listen<AsyncValue<void>>(dataManagementProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: $error',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              backgroundColor: AppColors.rose,
            ),
          );
        },
      );
    });

    final dataState = ref.watch(dataManagementProvider);
    final isLoading = dataState is AsyncLoading;

    if (houseId == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.slate800),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Data & Privacy',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.slate800,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AccountSection(houseId: houseId),
                const SizedBox(height: 24),
                _HouseDataSection(houseId: houseId),
                const SizedBox(height: 24),
                _ArchivedSection(houseId: houseId),
                const SizedBox(height: 24),
                const _LocalSection(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        if (isLoading)
          const ModalBarrier(dismissible: false, color: Colors.transparent),
        if (isLoading)
          Container(
            color: Colors.black26,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.slate500,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

// ─── Action Tile ─────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate800,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.slate400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Account Section ─────────────────────────────────────────────────────────

class _AccountSection extends ConsumerWidget {
  const _AccountSection({required this.houseId});

  final String houseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('Account'),
        _ActionTile(
          icon: Icons.person_off_outlined,
          iconColor: AppColors.rose,
          title: 'Delete My Account',
          subtitle: 'Permanently remove your account and data',
          onTap: () async {
            final confirmed = await showTypedConfirmDialog(
              context: context,
              title: 'Delete Account',
              description:
                  'This will anonymize your data and permanently delete your account. This cannot be undone.',
              confirmText: 'DELETE',
              actionLabel: 'Delete Account',
            );
            if (confirmed == true && context.mounted) {
              await ref.read(dataManagementProvider.notifier).deleteAccount();
              if (context.mounted) {
                context.go('/sign-in');
              }
            }
          },
        ),
      ],
    );
  }
}

// ─── House Data Section ───────────────────────────────────────────────────────

class _HouseDataSection extends ConsumerWidget {
  const _HouseDataSection({required this.houseId});

  final String houseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('House Data'),
        _ActionTile(
          icon: Icons.restart_alt_rounded,
          iconColor: AppColors.rose,
          title: 'Reset All Data',
          subtitle: 'Clear all house data permanently',
          onTap: () async {
            final confirmed = await showTypedConfirmDialog(
              context: context,
              title: 'Reset All Data',
              description:
                  'This will permanently delete all house data including issues, activity, leaderboard, and stats. This cannot be undone.',
              confirmText: 'RESET',
              actionLabel: 'Reset All Data',
            );
            if (confirmed == true) {
              await ref
                  .read(dataManagementProvider.notifier)
                  .resetHouseData(houseId: houseId, scope: 'all');
            }
          },
        ),
        _ActionTile(
          icon: Icons.assignment_outlined,
          iconColor: AppColors.orange,
          title: 'Clear Issues',
          subtitle: 'Delete all issues in the house',
          onTap: () async {
            final confirmed = await showTypedConfirmDialog(
              context: context,
              title: 'Clear Issues',
              description:
                  'This will permanently delete all issues. This cannot be undone.',
              confirmText: 'CLEAR',
              actionLabel: 'Clear Issues',
              actionColor: AppColors.orange,
            );
            if (confirmed == true) {
              await ref
                  .read(dataManagementProvider.notifier)
                  .resetHouseData(houseId: houseId, scope: 'issues');
            }
          },
        ),
        _ActionTile(
          icon: Icons.history_rounded,
          iconColor: AppColors.orange,
          title: 'Clear Activity Log',
          subtitle: 'Remove all activity history',
          onTap: () async {
            final confirmed = await showTypedConfirmDialog(
              context: context,
              title: 'Clear Activity Log',
              description:
                  'This will permanently delete all activity history. This cannot be undone.',
              confirmText: 'CLEAR',
              actionLabel: 'Clear Activity Log',
              actionColor: AppColors.orange,
            );
            if (confirmed == true) {
              await ref
                  .read(dataManagementProvider.notifier)
                  .resetHouseData(houseId: houseId, scope: 'activity');
            }
          },
        ),
        _ActionTile(
          icon: Icons.leaderboard_outlined,
          iconColor: AppColors.orange,
          title: 'Reset Leaderboard',
          subtitle: 'Clear all leaderboard scores',
          onTap: () async {
            final confirmed = await showTypedConfirmDialog(
              context: context,
              title: 'Reset Leaderboard',
              description:
                  'This will permanently reset all leaderboard data. This cannot be undone.',
              confirmText: 'RESET',
              actionLabel: 'Reset Leaderboard',
              actionColor: AppColors.orange,
            );
            if (confirmed == true) {
              await ref
                  .read(dataManagementProvider.notifier)
                  .resetHouseData(houseId: houseId, scope: 'leaderboard');
            }
          },
        ),
        _ActionTile(
          icon: Icons.bar_chart_rounded,
          iconColor: AppColors.orange,
          title: 'Reset Member Stats',
          subtitle: 'Clear all member statistics',
          onTap: () async {
            final confirmed = await showTypedConfirmDialog(
              context: context,
              title: 'Reset Member Stats',
              description:
                  'This will permanently reset all member statistics. This cannot be undone.',
              confirmText: 'RESET',
              actionLabel: 'Reset Member Stats',
              actionColor: AppColors.orange,
            );
            if (confirmed == true) {
              await ref
                  .read(dataManagementProvider.notifier)
                  .resetHouseData(houseId: houseId, scope: 'stats');
            }
          },
        ),
      ],
    );
  }
}

// ─── Archived Section ─────────────────────────────────────────────────────────

class _ArchivedSection extends ConsumerStatefulWidget {
  const _ArchivedSection({required this.houseId});

  final String houseId;

  @override
  ConsumerState<_ArchivedSection> createState() => _ArchivedSectionState();
}

class _ArchivedSectionState extends ConsumerState<_ArchivedSection> {
  int? _selectedDays;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('Archived Issues'),
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.archive_outlined,
                    color: AppColors.slate500,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Purge Archived Issues',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.slate800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Permanently delete archived issues',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.slate500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderMedium),
                ),
                child: DropdownButton<int?>(
                  value: _selectedDays,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.slate700,
                  ),
                  items: const [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text('All archived'),
                    ),
                    DropdownMenuItem<int?>(
                      value: 30,
                      child: Text('Older than 30 days'),
                    ),
                    DropdownMenuItem<int?>(
                      value: 60,
                      child: Text('Older than 60 days'),
                    ),
                    DropdownMenuItem<int?>(
                      value: 90,
                      child: Text('Older than 90 days'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedDays = value);
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () async {
                    final confirmed = await showTypedConfirmDialog(
                      context: context,
                      title: 'Purge Archived Issues',
                      description: _selectedDays == null
                          ? 'This will permanently delete all archived issues. This cannot be undone.'
                          : 'This will permanently delete archived issues older than $_selectedDays days. This cannot be undone.',
                      confirmText: 'PURGE',
                      actionLabel: 'Purge Issues',
                    );
                    if (confirmed == true && context.mounted) {
                      final count = await ref
                          .read(dataManagementProvider.notifier)
                          .purgeArchivedIssues(
                            houseId: widget.houseId,
                            olderThanDays: _selectedDays,
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '$count archived issue${count == 1 ? '' : 's'} deleted.',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.rose50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.rose100),
                    ),
                    child: Center(
                      child: Text(
                        'Purge Archived Issues',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.rose,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Local Section ────────────────────────────────────────────────────────────

class _LocalSection extends ConsumerWidget {
  const _LocalSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('Local'),
        _ActionTile(
          icon: Icons.cached_rounded,
          iconColor: AppColors.slate500,
          title: 'Clear App Cache',
          subtitle: 'Free up local storage',
          onTap: () async {
            await ref.read(dataManagementProvider.notifier).clearLocalCache();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'App cache cleared successfully.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
