import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// Centered confirm dialog for blocking a review author. Resolves `true` on
/// "Block", `false`/null on cancel or tap-outside. Matches the app's
/// DeleteReviewDialog style (rounded 16, two side-by-side buttons), with the
/// title/body scrollable so large Dynamic Type never clips.
class BlockUserDialog {
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String body,
    required String cancelLabel,
    required String blockLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => _BlockUserDialog(
        title: title,
        body: body,
        cancelLabel: cancelLabel,
        blockLabel: blockLabel,
      ),
    );
  }
}

class _BlockUserDialog extends StatelessWidget {
  const _BlockUserDialog({
    required this.title,
    required this.body,
    required this.cancelLabel,
    required this.blockLabel,
  });

  final String title;
  final String body;
  final String cancelLabel;
  final String blockLabel;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final danger = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFF07070)
        : const Color(0xFFE24B4A);
    return Dialog(
      backgroundColor: c.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title + body scroll together if Dynamic Type makes them tall,
            // so the action row below stays reachable on small screens.
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spaceSm),
                    Text(
                      body,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 13,
                        color: c.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spaceLg),
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    label: cancelLabel,
                    onTap: () => Navigator.of(context).pop(false),
                    filled: false,
                  ),
                ),
                const SizedBox(width: AppConstants.spaceSm),
                Expanded(
                  child: _DialogButton(
                    label: blockLabel,
                    onTap: () => Navigator.of(context).pop(true),
                    filled: true,
                    fillColor: danger,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.onTap,
    required this.filled,
    this.fillColor,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: filled ? fillColor : null,
          border: filled
              ? null
              : Border.all(color: c.borderSecondary, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: filled ? Colors.white : c.textPrimary,
          ),
        ),
      ),
    );
  }
}
