import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// What the user chose in the non-owner review action menu.
enum ReviewModerationAction { report, block }

/// Action menu shown on long-press of *someone else's* Tabemina review.
/// Two rows — Report review and Block this user — matching the B-1-1b / B-2-1
/// sheet style (drag handle, 16px top radius, cream/dark surface, safe-area).
/// Returns the chosen action, or null on cancel / tap-outside.
///
/// Block is destructive: its red icon + text is ALWAYS paired with the
/// literal "Block this user" label (colour is never the only signal).
class ReviewModerationSheet {
  static Future<ReviewModerationAction?> show(
    BuildContext context, {
    required String header,
    required String reportLabel,
    required String blockLabel,
    required String cancelLabel,
  }) {
    return showModalBottomSheet<ReviewModerationAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _Sheet(
        header: header,
        reportLabel: reportLabel,
        blockLabel: blockLabel,
        cancelLabel: cancelLabel,
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.header,
    required this.reportLabel,
    required this.blockLabel,
    required this.cancelLabel,
  });

  final String header;
  final String reportLabel;
  final String blockLabel;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final danger = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFF07070)
        : const Color(0xFFE24B4A);

    return Container(
      decoration: BoxDecoration(
        color: c.bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppConstants.spaceSm),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.borderSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.spaceLg,
                AppConstants.spaceMd,
                AppConstants.spaceLg,
                AppConstants.spaceSm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      header,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 0.5, color: c.borderPrimary),
            _OptionRow(
              icon: Icons.flag_outlined,
              label: reportLabel,
              color: c.textPrimary,
              onTap: () =>
                  Navigator.of(context).pop(ReviewModerationAction.report),
            ),
            _OptionRow(
              icon: Icons.block,
              label: blockLabel,
              color: danger,
              onTap: () =>
                  Navigator.of(context).pop(ReviewModerationAction.block),
            ),
            Divider(height: 1, thickness: 0.5, color: c.borderPrimary),
            _OptionRow(
              icon: Icons.close_rounded,
              label: cancelLabel,
              color: c.textSecondary,
              onTap: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: AppConstants.spaceSm),
          ],
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        // minHeight keeps a comfortable target; vertical padding lets the row
        // grow with larger Dynamic Type instead of clipping.
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spaceLg,
            vertical: AppConstants.spaceMd,
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: AppConstants.spaceMd),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: color,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
