import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

/// App-wide floating snackbar.
///
/// Floats just above the fixed bottom bar (DetailBottomBar / TabScaffold's
/// `BottomNavigationBar`) so it never sits on top of phone numbers, the
/// bookmark heart, or the action row. Two modes share the same surface so
/// success / undo / error confirmations all feel like the same product.
///
/// [icon] is optional — when present, it sits to the left of the text in a
/// 14px size, tinted [iconColor] if given (otherwise the snackbar text
/// color).
void showTabeminaSnackbar(
  BuildContext context, {
  required String message,
  IconData? icon,
  Color? iconColor,
  Duration duration = const Duration(seconds: 2),
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final c = AppColors.of(context);
  final bottomInset = MediaQuery.of(context).padding.bottom;

  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.snackbarBg,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.only(
          left: AppConstants.spaceLg,
          right: AppConstants.spaceLg,
          // 72 ≈ DetailBottomBar height (56) + breathing room (16). Adding
          // the system inset keeps the gap consistent on Dynamic Island /
          // gesture-bar devices.
          bottom: 72 + bottomInset,
        ),
        duration: duration,
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: iconColor ?? c.snackbarText),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                message,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: c.snackbarText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}
