import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// Fixed top bar: back arrow / "Write review" / "Draft" link.
///
/// The back button delegates the discard-confirmation decision to the
/// parent so a draft check can live in the screen state. The "Draft" link
/// manually saves the form as a draft via [onDraft]; it's hidden entirely
/// when [onDraft] is null (edit mode, or an empty form with nothing to
/// save). We use the iOS-style chevron because write-review is now a push
/// route (not a modal), and the back arrow matches the swipe-back gesture's
/// mental model.
class ReviewTopBar extends StatelessWidget implements PreferredSizeWidget {
  const ReviewTopBar({
    super.key,
    required this.title,
    required this.draftLabel,
    required this.onClose,
    this.onDraft,
  });

  final String title;
  final String draftLabel;
  final VoidCallback onClose;

  /// Manual "임시저장" save. Null hides the button (edit mode / empty form).
  final VoidCallback? onDraft;

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
                    color: c.textSecondary,
                  ),
                  onPressed: onClose,
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
                if (onDraft != null)
                  TextButton(
                    onPressed: onDraft,
                    child: Text(
                      draftLabel,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: c.primary,
                      ),
                    ),
                  )
                else
                  // Keep the title centered when the button is hidden by
                  // balancing the leading back-arrow's width.
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
