import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/bookmark_pulse.dart';

/// Sticky bottom action bar — primary "Write review" CTA plus square
/// save/route buttons.
///
/// Save state is owned by the parent (it lives in the bookmarks Notifier so
/// the action row and bottom bar stay in sync) — this widget just renders
/// the icon according to [saved].
class DetailBottomBar extends StatelessWidget {
  const DetailBottomBar({
    super.key,
    required this.onWriteReview,
    required this.onRoute,
    required this.onSaveToggle,
    required this.saved,
  });

  final VoidCallback onWriteReview;
  final VoidCallback onRoute;
  final VoidCallback onSaveToggle;
  final bool saved;

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
              BookmarkPulse(
                saved: saved,
                child: _SquareButton(
                  icon: saved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_outline_rounded,
                  color: saved ? c.primary : c.textSecondary,
                  onTap: onSaveToggle,
                ),
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
