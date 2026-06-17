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
        // Floating snackbars are anchored above whichever bar the nearest
        // Scaffold has (DetailBottomBar via `bottomNavigationBar`, or the
        // tab bar when shown from a tab branch). Manually adding the bar's
        // height was double-counting and pushing the pill into the middle
        // of the page — `bottom: 8` is just the breathing-room gap.
        margin: const EdgeInsets.only(
          left: AppConstants.spaceLg,
          right: AppConstants.spaceLg,
          bottom: AppConstants.spaceSm,
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

/// Terracotta "action blocked" snackbar (B-3-3).
///
/// Reuses the same [ScaffoldMessenger] `SnackBar` surface as
/// [showTabeminaSnackbar], so its content already sits under a Material (no
/// no-Material-ancestor fallback styling). Used when an action is intentionally
/// blocked — e.g. submitting a review while offline — or fails: a strong
/// terracotta pill with [message], optional [subtext], and an optional
/// [retryLabel]/[onRetry] action. Auto-dismisses after [duration] (~4s) and is
/// swipe-dismissible. Tapping retry dismisses the snackbar and calls [onRetry].
void showTabeminaBlockedSnackbar(
  BuildContext context, {
  required String message,
  String? subtext,
  VoidCallback? onRetry,
  String? retryLabel,
  Duration duration = const Duration(seconds: 4),
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final c = AppColors.of(context);

  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.snackbarBlockedFill,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        ),
        margin: const EdgeInsets.only(
          left: AppConstants.spaceLg,
          right: AppConstants.spaceLg,
          bottom: AppConstants.spaceSm,
        ),
        duration: duration,
        dismissDirection: DismissDirection.horizontal,
        content: Row(
          children: [
            Icon(Icons.wifi_off_rounded, size: 18, color: c.snackbarBlockedIcon),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.snackbarBlockedText,
                    ),
                  ),
                  if (subtext != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtext,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 12,
                        color: c.snackbarBlockedSubtext,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        action: (onRetry != null && retryLabel != null)
            ? SnackBarAction(
                label: retryLabel,
                textColor: c.snackbarBlockedRetry,
                onPressed: onRetry,
              )
            : null,
      ),
    );
}
