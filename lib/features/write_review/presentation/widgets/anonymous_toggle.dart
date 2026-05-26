import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

class AnonymousToggle extends StatelessWidget {
  const AnonymousToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    required this.hint,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spaceLg,
        AppConstants.spaceLg,
        AppConstants.spaceLg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: AppColors.onPrimary,
                activeTrackColor: c.primary,
              ),
              const SizedBox(width: AppConstants.spaceSm),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (value) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 60),
              child: Text(
                hint,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 11,
                  color: c.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
