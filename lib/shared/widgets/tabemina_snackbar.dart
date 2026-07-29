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
        // This surface never carries a SnackBarAction, so Flutter would derive
        // persist = false anyway. Stated explicitly so the invariant survives
        // anyone later adding an action here — the derived-true case fires its
        // timeout without hiding the bar, which is the bug the blocked variant
        // below documents.
        persist: false,
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
///
/// [icon] defaults to the no-connection glyph because that is what most blocked
/// actions are. Failures that are NOT network-shaped — a rejected write, a
/// permission error — should pass something honest instead
/// (e.g. `Icons.error_outline_rounded`); a wifi-off glyph on a non-network
/// failure sends the user to check their signal for no reason.
///
/// This surface is for genuine failures and hard blocks only. An outcome that
/// merely isn't confirmed yet belongs on [showTabeminaSnackbar] — terracotta
/// reads as "something went wrong", and pairing that with a message saying
/// otherwise just makes the two contradict each other.
void showTabeminaBlockedSnackbar(
  BuildContext context, {
  required String message,
  String? subtext,
  VoidCallback? onRetry,
  String? retryLabel,
  Duration duration = const Duration(seconds: 4),
  IconData icon = Icons.wifi_off_rounded,
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
        // Honor the finite [duration] even with a retry action present: Flutter
        // otherwise derives persist = (action != null) = true, whose timeout
        // fires but doesn't hide the bar — leaving it stuck on screen.
        persist: false,
        dismissDirection: DismissDirection.horizontal,
        content: Row(
          children: [
            Icon(icon, size: 18, color: c.snackbarBlockedIcon),
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
