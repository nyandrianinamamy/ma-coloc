import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/issue.dart';
import '../../providers/house_provider.dart';
import '../../providers/issue_provider.dart';
import '../../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// CreateIssueScreen — two-phase: camera view → details form
// ---------------------------------------------------------------------------

class CreateIssueScreen extends ConsumerStatefulWidget {
  const CreateIssueScreen({super.key});

  @override
  ConsumerState<CreateIssueScreen> createState() => _CreateIssueScreenState();
}

class _CreateIssueScreenState extends ConsumerState<CreateIssueScreen> {
  bool _showDetails = false;
  String _selectedType = 'Chore';
  bool _isAnonymous = false;
  final TextEditingController _titleController = TextEditingController();

  XFile? _photo;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _onPhotoPicked(XFile photo) {
    setState(() {
      _photo = photo;
      _showDetails = true;
    });
  }

  void _retake() {
    setState(() => _showDetails = false);
  }

  Future<void> _post() async {
    final houseId = ref.read(currentHouseIdProvider).valueOrNull;
    if (houseId == null) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(issueActionsProvider.notifier).create(
            houseId: houseId,
            type: IssueType.values.firstWhere(
              (t) => t.name == _selectedType.toLowerCase(),
              orElse: () => IssueType.chore,
            ),
            title:
                _titleController.text.isNotEmpty ? _titleController.text : null,
            anonymous: _isAnonymous,
            photo: _photo,
          );
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _showDetails
              ? _DetailsForm(
                  key: const ValueKey('details'),
                  selectedType: _selectedType,
                  isAnonymous: _isAnonymous,
                  titleController: _titleController,
                  photo: _photo,
                  isSubmitting: _isSubmitting,
                  onTypeChanged: (t) => setState(() => _selectedType = t),
                  onAnonymousChanged: (v) => setState(() => _isAnonymous = v),
                  onRetake: _retake,
                  onPost: _post,
                )
              : _CameraView(
                  key: const ValueKey('camera'),
                  onClose: () => context.pop(),
                  onPhotoPicked: _onPhotoPicked,
                ),
        ),
        if (_isSubmitting)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.4),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Phase 1 — Camera View
// ---------------------------------------------------------------------------

class _CameraView extends StatelessWidget {
  const _CameraView({
    super.key,
    required this.onClose,
    required this.onPhotoPicked,
  });

  final VoidCallback onClose;
  final ValueChanged<XFile> onPhotoPicked;

  Future<void> _pickImage(ImageSource source) async {
    final photo = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (photo != null) {
      onPhotoPicked(photo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final viewfinderWidth = screenSize.width * 0.8;
    final viewfinderHeight = screenSize.height * 0.5;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Full-screen dark placeholder for camera
            Positioned.fill(
              child: Container(color: const Color(0xFF0A0A0A)),
            ),

            // Center viewfinder guide
            Center(
              child: SizedBox(
                width: viewfinderWidth,
                height: viewfinderHeight,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Rounded rectangle border guide
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                    ),
                    // Camera icon + label
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Point at the mess or\nbroken thing',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    // Close button
                    GestureDetector(
                      onTap: onClose,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // "NEW ISSUE" label
                    const Text(
                      'NEW ISSUE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const Spacer(),
                    // Invisible placeholder to balance the close button
                    const SizedBox(width: 40),
                  ],
                ),
              ),
            ),

            // Bottom controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(40, 20, 40, 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Gallery button
                    GestureDetector(
                      onTap: () => _pickImage(ImageSource.gallery),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(
                          Icons.photo_library_outlined,
                          color: Colors.white.withValues(alpha: 0.9),
                          size: 24,
                        ),
                      ),
                    ),

                    // Capture button
                    GestureDetector(
                      onTap: () => _pickImage(ImageSource.camera),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: Center(
                          child: Container(
                            width: 62,
                            height: 62,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Ghost toggle button
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(
                          Icons.bedtime_outlined,
                          color: Colors.white.withValues(alpha: 0.9),
                          size: 24,
                        ),
                      ),
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
// Phase 2 — Details Form
// ---------------------------------------------------------------------------

class _DetailsForm extends StatelessWidget {
  const _DetailsForm({
    super.key,
    required this.selectedType,
    required this.isAnonymous,
    required this.titleController,
    required this.photo,
    required this.isSubmitting,
    required this.onTypeChanged,
    required this.onAnonymousChanged,
    required this.onRetake,
    required this.onPost,
  });

  final String selectedType;
  final bool isAnonymous;
  final TextEditingController titleController;
  final XFile? photo;
  final bool isSubmitting;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<bool> onAnonymousChanged;
  final VoidCallback onRetake;
  final VoidCallback onPost;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: isSubmitting ? null : onRetake,
                    child: Text(
                      'Retake',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isSubmitting
                            ? AppColors.slate500.withValues(alpha: 0.4)
                            : AppColors.slate500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate800,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: isSubmitting ? null : onPost,
                    child: Text(
                      'Post',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isSubmitting
                            ? AppColors.emerald.withValues(alpha: 0.4)
                            : AppColors.emerald,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo preview
                    _PhotoPreview(
                      isAnonymous: isAnonymous,
                      photo: photo,
                    ),
                    const SizedBox(height: 24),

                    // Type selection grid
                    _TypeGrid(
                      selectedType: selectedType,
                      onTypeChanged: onTypeChanged,
                    ),
                    const SizedBox(height: 24),

                    // Title input
                    _TitleInput(controller: titleController),
                    const SizedBox(height: 20),

                    // Anonymous toggle
                    _AnonymousToggle(
                      isAnonymous: isAnonymous,
                      onChanged: onAnonymousChanged,
                    ),
                    const SizedBox(height: 28),

                    // Post button
                    _PostButton(
                      onPost: onPost,
                      isSubmitting: isSubmitting,
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
// Photo Preview
// ---------------------------------------------------------------------------

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({
    required this.isAnonymous,
    required this.photo,
  });

  final bool isAnonymous;
  final XFile? photo;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Stack(
        children: [
          // Photo or placeholder background
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: photo != null
                  ? Image.file(
                      File(photo!.path),
                      fit: BoxFit.cover,
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1E293B), Color(0xFF334155)],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.white.withValues(alpha: 0.3),
                          size: 48,
                        ),
                      ),
                    ),
            ),
          ),

          // Author badge (bottom-right)
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bedtime_outlined,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 13,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isAnonymous ? 'Anonymous' : 'You',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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

// ---------------------------------------------------------------------------
// Type Grid
// ---------------------------------------------------------------------------

class _TypeGrid extends StatelessWidget {
  const _TypeGrid({
    required this.selectedType,
    required this.onTypeChanged,
  });

  final String selectedType;
  final ValueChanged<String> onTypeChanged;

  static const List<_TypeOption> _types = [
    _TypeOption(
      label: 'Chore',
      icon: Icons.flash_on_rounded,
      color: AppColors.orange,
      bgColor: AppColors.orange50,
    ),
    _TypeOption(
      label: 'Grocery',
      icon: Icons.inventory_2_outlined,
      color: AppColors.blue,
      bgColor: AppColors.blue50,
    ),
    _TypeOption(
      label: 'Repair',
      icon: Icons.build_outlined,
      color: AppColors.rose,
      bgColor: AppColors.rose50,
    ),
    _TypeOption(
      label: 'Other',
      icon: Icons.error_outline,
      color: AppColors.slate500,
      bgColor: AppColors.slate100,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Type',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.slate500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.8,
          children: _types.map((t) {
            final isActive = selectedType == t.label;
            return GestureDetector(
              onTap: () => onTypeChanged(t.label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isActive ? t.bgColor : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isActive ? t.color : AppColors.borderMedium,
                    width: isActive ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      t.icon,
                      color: isActive ? t.color : AppColors.slate400,
                      size: 18,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      t.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isActive ? t.color : AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _TypeOption {
  const _TypeOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
}

// ---------------------------------------------------------------------------
// Title Input
// ---------------------------------------------------------------------------

class _TitleInput extends StatefulWidget {
  const _TitleInput({required this.controller});

  final TextEditingController controller;

  @override
  State<_TitleInput> createState() => _TitleInputState();
}

class _TitleInputState extends State<_TitleInput> {
  final FocusNode _focusNode = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _hasFocus = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Quick Title',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.slate500,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(width: 6),
            Text(
              '(Optional)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hasFocus ? AppColors.emerald : AppColors.borderMedium,
              width: _hasFocus ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              hintText: 'e.g. Dishes in sink again…',
              hintStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textTertiary,
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Anonymous Toggle
// ---------------------------------------------------------------------------

class _AnonymousToggle extends StatelessWidget {
  const _AnonymousToggle({
    required this.isAnonymous,
    required this.onChanged,
  });

  final bool isAnonymous;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isAnonymous
            ? const Color(0xFFEEF2FF) // indigo-50
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAnonymous ? AppColors.indigo : AppColors.borderMedium,
          width: isAnonymous ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Ghost icon circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isAnonymous
                  ? AppColors.indigo.withValues(alpha: 0.15)
                  : AppColors.slate100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bedtime_outlined,
              color: isAnonymous ? AppColors.indigo : AppColors.slate400,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Post Anonymously',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isAnonymous
                        ? AppColors.indigo
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  "Don't show your name",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Toggle switch
          Switch(
            value: isAnonymous,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.indigo,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppColors.slate300,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Post Button
// ---------------------------------------------------------------------------

class _PostButton extends StatelessWidget {
  const _PostButton({
    required this.onPost,
    required this.isSubmitting,
  });

  final VoidCallback onPost;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.emerald.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: isSubmitting ? null : onPost,
          icon: isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_rounded, size: 18),
          label: const Text(
            'Post to House',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.emerald,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.emerald.withValues(alpha: 0.6),
            disabledForegroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
