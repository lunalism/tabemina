import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// Fixed top bar: back arrow / "Write review" / auto-save status.
///
/// The back button delegates the leave/discard decision to the parent. In
/// create mode the form auto-saves, so instead of a manual save button the
/// trailing slot shows a quiet "saved" status once a draft exists this session
/// — driven by [savedIndicator] so it updates WITHOUT a parent rebuild. Both
/// [savedIndicator] and [savedLabel] are null in edit mode (no draft system).
/// We use the iOS-style chevron because write-review is a push route (not a
/// modal), and the back arrow matches the swipe-back gesture's mental model.
class ReviewTopBar extends StatelessWidget implements PreferredSizeWidget {
  const ReviewTopBar({
    super.key,
    required this.title,
    required this.onClose,
    this.closeEnabled = true,
    this.savedIndicator,
    this.savedLabel,
  });

  final String title;
  final VoidCallback onClose;

  /// False while the screen is mid-submit or mid-cleanup. The arrow stays
  /// VISIBLE and simply goes inert — a control that vanishes and reappears
  /// reads as a glitch, and the user still needs to see where back lives.
  ///
  /// This is presentation only. `_onClose` enforces the same block itself, so
  /// the guard does not depend on this flag being wired correctly.
  final bool closeEnabled;

  /// Flips true once the create-mode draft has been auto-saved this session.
  /// Watched locally (ValueListenableBuilder) so the indicator updates without
  /// rebuilding the parent form. Null in edit mode.
  final ValueListenable<bool>? savedIndicator;

  /// Localized "임시저장됨" label for the saved indicator. Null in edit mode.
  final String? savedLabel;

  static const double _height = 48;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Material(
      color: c.bgCard,
      child: SafeArea(
        bottom: false,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: c.borderPrimary, width: 0.5),
            ),
          ),
          child: SizedBox(
            height: _height,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                    // Dimmed rather than hidden. The explicit color has to be
                    // branched here because IconButton's own disabled tint is
                    // overridden by passing one at all.
                    color: closeEnabled ? c.textSecondary : c.textTertiary,
                  ),
                  onPressed: closeEnabled ? onClose : null,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ),
                if (savedIndicator != null && savedLabel != null)
                  // Scoped to its own listenable: flipping it rebuilds ONLY this
                  // indicator, never the parent form.
                  ValueListenableBuilder<bool>(
                    valueListenable: savedIndicator!,
                    builder: (context, saved, _) {
                      if (!saved) return const SizedBox(width: 48);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.cloud_done_outlined,
                              size: 14,
                              color: c.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              savedLabel!,
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                else
                  // Keep the title centered (balance the leading back-arrow).
                  const SizedBox(width: 48),
                const SizedBox(width: AppConstants.spaceXs),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
