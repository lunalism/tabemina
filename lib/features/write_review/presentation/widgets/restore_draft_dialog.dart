import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// Shown when the write-review screen opens in create mode and a saved draft
/// exists. Resolves to:
///   - `true`  → Restore (load the draft into the form)
///   - `false` → Discard (clear the draft, start fresh)
///   - `null`  → never (barrier is non-dismissible, so the user must choose)
///
/// Restore is the coral primary action; Discard is a secondary outline.
class RestoreDraftDialog {
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String body,
    required String savedAtLabel,
    required String restoreLabel,
    required String discardLabel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _RestoreContent(
        title: title,
        body: body,
        savedAtLabel: savedAtLabel,
        restoreLabel: restoreLabel,
        discardLabel: discardLabel,
      ),
    );
  }
}

class _RestoreContent extends StatelessWidget {
  const _RestoreContent({
    required this.title,
    required this.body,
    required this.savedAtLabel,
    required this.restoreLabel,
    required this.discardLabel,
  });

  final String title;
  final String body;
  final String savedAtLabel;
  final String restoreLabel;
  final String discardLabel;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Dialog(
      backgroundColor: c.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
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
                fontWeight: FontWeight.w500,
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
            const SizedBox(height: 4),
            Text(
              savedAtLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 12,
                color: c.textTertiary,
              ),
            ),
            const SizedBox(height: AppConstants.spaceLg),
            // Primary: Restore (coral)
            InkWell(
              onTap: () => Navigator.of(context).pop(true),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: c.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  restoreLabel,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spaceSm),
            // Secondary: Discard (outline)
            InkWell(
              onTap: () => Navigator.of(context).pop(false),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  border: Border.all(color: c.borderPrimary, width: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  discardLabel,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: c.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
