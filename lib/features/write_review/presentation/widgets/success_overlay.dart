import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// Brief celebratory card shown after a successful post.
///
/// Stays modal for [autoDismissAfter] (default 1.5s), then resolves so the
/// screen above can pop. Auto-dismiss is driven by a one-shot Future so the
/// parent can compose it with [Future.wait] or await it directly.
class SuccessOverlay {
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String subtitle,
    Duration autoDismissAfter = const Duration(milliseconds: 1500),
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (ctx) => _SuccessContent(
        title: title,
        subtitle: subtitle,
        autoDismissAfter: autoDismissAfter,
      ),
    );
  }
}

class _SuccessContent extends StatefulWidget {
  const _SuccessContent({
    required this.title,
    required this.subtitle,
    required this.autoDismissAfter,
  });

  final String title;
  final String subtitle;
  final Duration autoDismissAfter;

  @override
  State<_SuccessContent> createState() => _SuccessContentState();
}

class _SuccessContentState extends State<_SuccessContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scale;

  @override
  void initState() {
    super.initState();
    _scale = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..forward();
    Future.delayed(widget.autoDismissAfter, () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Dialog(
      backgroundColor: c.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spaceXl,
          vertical: 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: CurvedAnimation(
                parent: _scale,
                curve: Curves.easeOutBack,
              ),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 36,
                  color: c.primary,
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spaceMd),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 13,
                color: c.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
