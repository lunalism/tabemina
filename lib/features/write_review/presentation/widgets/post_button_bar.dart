import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// Sticky bottom bar with the single primary action.
///
/// Enable-disable is computed by the parent — the parent owns "is the form
/// valid?" logic, this widget just renders the resulting state.
class PostButtonBar extends StatelessWidget {
  const PostButtonBar({
    super.key,
    required this.enabled,
    required this.posting,
    required this.onPost,
    required this.label,
    required this.postingLabel,
  });

  final bool enabled;
  final bool posting;
  final VoidCallback onPost;
  final String label;
  final String postingLabel;

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
          child: InkWell(
            onTap: enabled && !posting ? onPost : null,
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              height: 48,
              decoration: BoxDecoration(
                color: enabled ? c.primary : c.bgSkeleton,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: posting
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
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
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: enabled ? AppColors.onPrimary : c.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: enabled
                                ? AppColors.onPrimary
                                : c.textSecondary,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
