import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// Confirmation dialog shown when the user taps X with unsaved content.
///
/// Resolves to `true` if the user chose to discard. `null` (closed without a
/// choice) and `false` ("Keep editing") both mean the caller should stay.
class DiscardDialog {
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String body,
    required String discardLabel,
    required String keepLabel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _DiscardContent(
        title: title,
        body: body,
        discardLabel: discardLabel,
        keepLabel: keepLabel,
      ),
    );
  }
}

class _DiscardContent extends StatelessWidget {
  const _DiscardContent({
    required this.title,
    required this.body,
    required this.discardLabel,
    required this.keepLabel,
  });

  final String title;
  final String body;
  final String discardLabel;
  final String keepLabel;

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
            const SizedBox(height: AppConstants.spaceLg),
            InkWell(
              onTap: () => Navigator.of(context).pop(true),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 44,
                alignment: Alignment.center,
                child: Text(
                  discardLabel,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: c.errorText,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            InkWell(
              onTap: () => Navigator.of(context).pop(false),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: c.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  keepLabel,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onPrimary,
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
