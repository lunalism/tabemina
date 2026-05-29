import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// Sticky bottom bar with the single primary action.
///
/// With the pre-upload flow, photos finish uploading while the user writes,
/// so the bar reflects upload readiness rather than per-photo progress:
/// - normal: coral + [label]
/// - photos uploading: gray + [uploadingLabel] + small spinner (disabled)
/// - failed uploads: coral + [retryLabel] → [onRetryFailed]
/// - posting (Firestore write): dimmed coral + spinner + [postingLabel]
class PostButtonBar extends StatelessWidget {
  const PostButtonBar({
    super.key,
    required this.enabled,
    required this.posting,
    required this.uploading,
    required this.hasFailed,
    required this.onPost,
    required this.onRetryFailed,
    required this.label,
    required this.postingLabel,
    required this.uploadingLabel,
    required this.retryLabel,
  });

  final bool enabled;
  final bool posting;
  final bool uploading;
  final bool hasFailed;
  final VoidCallback onPost;
  final VoidCallback onRetryFailed;
  final String label;
  final String postingLabel;
  final String uploadingLabel;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.bgPage,
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
          child: _button(c),
        ),
      ),
    );
  }

  Widget _button(AppColors c) {
    // Retry takes priority over the disabled "uploading" look so the user
    // can act on failures without waiting.
    if (hasFailed && !posting) {
      return _Tappable(
        onTap: onRetryFailed,
        color: c.primary,
        child: _RowText(
          icon: Icons.refresh_rounded,
          label: retryLabel,
          color: AppColors.onPrimary,
        ),
      );
    }
    if (uploading && !posting) {
      return _Tappable(
        onTap: null,
        color: c.bgSkeleton,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: c.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              uploadingLabel,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: c.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    if (posting) {
      return _Tappable(
        onTap: null,
        color: c.primary.withValues(alpha: 0.7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.onPrimary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              postingLabel,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.onPrimary,
              ),
            ),
          ],
        ),
      );
    }
    return _Tappable(
      onTap: enabled ? onPost : null,
      color: enabled ? c.primary : c.bgSkeleton,
      child: _RowText(
        icon: Icons.check_rounded,
        label: label,
        color: enabled ? AppColors.onPrimary : c.textSecondary,
      ),
    );
  }
}

class _Tappable extends StatelessWidget {
  const _Tappable({
    required this.onTap,
    required this.color,
    required this.child,
  });

  final VoidCallback? onTap;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 48,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

class _RowText extends StatelessWidget {
  const _RowText({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
