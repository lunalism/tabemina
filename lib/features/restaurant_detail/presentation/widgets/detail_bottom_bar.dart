import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../presentation/providers/bookmark_providers.dart';

/// Sticky bottom action bar — primary "Write review" CTA plus square
/// save/route buttons.
///
/// The save button watches [isBookmarkedProvider] on its own (via the
/// embedded [_BookmarkSquareButton] ConsumerWidget) so a bookmark toggle
/// rebuilds just the 40×40 icon — not the whole detail screen. We don't
/// animate the icon swap: the bounce was masking a layout shake we
/// couldn't fully suppress, and a plain swap reads cleaner anyway.
class DetailBottomBar extends StatelessWidget {
  const DetailBottomBar({
    super.key,
    required this.placeId,
    required this.onWriteReview,
    required this.onRoute,
    required this.onSaveToggle,
  });

  final String placeId;
  final VoidCallback onWriteReview;
  final VoidCallback onRoute;
  final VoidCallback onSaveToggle;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border(top: BorderSide(color: c.borderPrimary, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.spaceLg,
            8,
            AppConstants.spaceLg,
            8,
          ),
          child: Row(
            children: [
              Expanded(
                child: _PrimaryCta(onTap: onWriteReview),
              ),
              const SizedBox(width: 8),
              _BookmarkSquareButton(
                placeId: placeId,
                onTap: onSaveToggle,
              ),
              const SizedBox(width: 8),
              _SquareButton(
                icon: Icons.navigation_outlined,
                color: c.textSecondary,
                onTap: onRoute,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: c.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.edit_outlined, size: 16, color: AppColors.onPrimary),
            SizedBox(width: 6),
            Text(
              'Write review',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: c.borderPrimary, width: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

/// Lives at the leaf — watches [isBookmarkedProvider] so that toggling a
/// bookmark only rebuilds this 40×40 square, never the containing
/// [DetailBottomBar] or its parent scaffold. That's the load-bearing piece
/// of the no-shake fix.
class _BookmarkSquareButton extends ConsumerWidget {
  const _BookmarkSquareButton({required this.placeId, required this.onTap});

  final String placeId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final saved = ref.watch(isBookmarkedProvider(placeId));
    return _SquareButton(
      icon: saved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
      color: saved ? c.primary : c.textSecondary,
      onTap: onTap,
    );
  }
}
