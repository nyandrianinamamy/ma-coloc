import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:macoloc/src/theme/app_theme.dart';

Future<bool?> showTypedConfirmDialog({
  required BuildContext context,
  required String title,
  required String description,
  required String confirmText,
  String actionLabel = 'Confirm',
  Color actionColor = AppColors.rose,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => _TypedConfirmDialog(
      title: title,
      description: description,
      confirmText: confirmText,
      actionLabel: actionLabel,
      actionColor: actionColor,
    ),
  );
}

class _TypedConfirmDialog extends StatefulWidget {
  const _TypedConfirmDialog({
    required this.title,
    required this.description,
    required this.confirmText,
    required this.actionLabel,
    required this.actionColor,
  });

  final String title;
  final String description;
  final String confirmText;
  final String actionLabel;
  final Color actionColor;

  @override
  State<_TypedConfirmDialog> createState() => _TypedConfirmDialogState();
}

class _TypedConfirmDialogState extends State<_TypedConfirmDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isConfirmEnabled = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final matches =
        _controller.text.trim().toLowerCase() ==
        widget.confirmText.toLowerCase();
    if (matches != _isConfirmEnabled) {
      setState(() {
        _isConfirmEnabled = matches;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.title,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.slate800,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.description,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.slate500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Type "${widget.confirmText}" to confirm:',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.slate800,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.slate800,
            ),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.slate300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.slate300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.slate500),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.slate500,
            ),
          ),
        ),
        TextButton(
          onPressed:
              _isConfirmEnabled
                  ? () => Navigator.of(context).pop(true)
                  : null,
          child: Text(
            widget.actionLabel,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _isConfirmEnabled ? widget.actionColor : AppColors.slate300,
            ),
          ),
        ),
      ],
    );
  }
}
