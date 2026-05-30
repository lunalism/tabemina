import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../domain/entities/report_reason.dart';
import '../report_labels.dart';

/// "Report review" bottom sheet — single-select reason list. Matches the
/// B-1-1b action sheet style (drag handle, 16px top radius, cream/dark
/// surface, safe-area inset). Tapping a reason submits immediately (no extra
/// confirm), popping with the chosen [ReportReason]; returns null on cancel.
///
/// Content is scrollable and capped at ~60% of screen height so it works on
/// an iPhone SE and respects large Dynamic Type without clipping (rows grow
/// with the text rather than sitting in fixed-height boxes).
class ReportReviewSheet {
  static Future<ReportReason?> show(BuildContext context, ReportLabels labels) {
    return showModalBottomSheet<ReportReason>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _Sheet(labels: labels),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.labels});

  final ReportLabels labels;

  IconData _iconFor(ReportReason reason) => switch (reason) {
    ReportReason.spam => Icons.block_outlined,
    ReportReason.offensive => Icons.warning_amber_rounded,
    ReportReason.hate => Icons.do_not_disturb_alt_outlined,
    ReportReason.offTopic => Icons.wrong_location_outlined,
    ReportReason.other => Icons.more_horiz_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final maxHeight = MediaQuery.of(context).size.height * 0.6;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
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
                AppConstants.spaceLg,
                AppConstants.spaceLg,
                AppConstants.spaceSm,
              ),
              child: Row(
                children: [
                  // Single subtle warning accent — paired with the text label
                  // so colour is never the only signal.
                  Icon(Icons.flag_outlined, size: 18, color: c.warningText),
                  const SizedBox(width: AppConstants.spaceSm),
                  Expanded(
                    child: Text(
                      labels.sheetTitle,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 0.5, color: c.borderPrimary),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final reason in ReportReason.values)
                      _ReasonRow(
                        icon: _iconFor(reason),
                        label: labels.labelFor(reason),
                        onTap: () => Navigator.of(context).pop(reason),
                      ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, thickness: 0.5, color: c.borderPrimary),
            _ReasonRow(
              icon: Icons.close_rounded,
              label: labels.cancel,
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

class _ReasonRow extends StatelessWidget {
  const _ReasonRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Override for the neutral default (used by the Cancel row).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final iconColor = color ?? c.textSecondary;
    final textColor = color ?? c.textPrimary;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        // minHeight keeps the tap target comfortable, but vertical padding
        // lets the row grow with larger Dynamic Type instead of clipping.
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spaceLg,
            vertical: AppConstants.spaceMd,
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: iconColor),
              const SizedBox(width: AppConstants.spaceMd),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: textColor,
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
