import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../mypage_labels.dart';

/// Confirmation dialog for deleting a review. Resolves `true` on confirm,
/// `false`/null on cancel or tap-outside.
class DeleteReviewDialog {
  static Future<bool?> show(BuildContext context, MyPageLabels labels) {
    return showDialog<bool>(
      context: context,
      builder: (_) => _DeleteReviewDialog(labels: labels),
    );
  }
}

class _DeleteReviewDialog extends StatelessWidget {
  const _DeleteReviewDialog({required this.labels});

  final MyPageLabels labels;

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
            Text(
              labels.deleteReviewConfirmTitle,
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
              labels.deleteReviewConfirmBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 13,
                color: c.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppConstants.spaceLg),
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    label: labels.cancel,
                    onTap: () => Navigator.of(context).pop(false),
                    filled: false,
                  ),
                ),
                const SizedBox(width: AppConstants.spaceSm),
                Expanded(
                  child: _DialogButton(
                    label: labels.delete,
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
