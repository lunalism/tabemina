import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_locale_provider.dart';
import '../../../../presentation/providers/bookmark_providers.dart';
import '../../../../shared/widgets/tab_scaffold.dart';
import '../detail_labels.dart';

/// Three-up action row under the info header: Review / Save / Route.
/// (Share was cut from v1 — the tile was dead; the v1.1 backlog revisits
/// sharing.)
///
/// The "Review" CTA is filled with a faint coral tint so it reads as the
/// primary action — the rest are outline so they don't compete with the
/// fixed bottom bar's "Write review" button. The Save button is wrapped
/// in [_BookmarkActionButton] (its own ConsumerWidget) so a bookmark
/// toggle rebuilds only the Save tile — the rest of the scroll body
/// stays put. The icon swap is intentionally un-animated.
class ActionButtons extends ConsumerWidget {
  const ActionButtons({
    super.key,
    required this.placeId,
    required this.onReview,
    required this.onSave,
    required this.onRoute,
  });

  final String placeId;
  final VoidCallback onReview;
  final VoidCallback onSave;
  final VoidCallback onRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final lang = ref.watch(appLocaleProvider).languageCode;
    final labels = DetailLabels.of(lang);
    final reviewLabel = NavLabels.of(lang).review;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spaceLg,
        AppConstants.spaceLg,
        AppConstants.spaceLg,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: Icons.edit_outlined,
              label: reviewLabel,
              filled: true,
              color: c.primary,
              onTap: onReview,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _BookmarkActionButton(
              placeId: placeId,
              onTap: onSave,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionButton(
              icon: Icons.navigation_outlined,
              label: labels.route,
              color: c.textSecondary,
              onTap: onRoute,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: filled ? color.withValues(alpha: 0.1) : null,
          border: Border.all(color: c.borderPrimary, width: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 11,
                fontWeight: filled ? FontWeight.w500 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Save tile — watches [isBookmarkedProvider] locally so a toggle rebuilds
/// just this 56-tall slot, leaving the surrounding CustomScrollView's
/// slivers (including the hero gallery) untouched.
class _BookmarkActionButton extends ConsumerWidget {
  const _BookmarkActionButton({required this.placeId, required this.onTap});

  final String placeId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final saved = ref.watch(isBookmarkedProvider(placeId));
    final lang = ref.watch(appLocaleProvider).languageCode;
    return _ActionButton(
      icon: saved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
      label: DetailLabels.of(lang).save,
      color: saved ? c.primary : c.textSecondary,
      onTap: onTap,
    );
  }
}
