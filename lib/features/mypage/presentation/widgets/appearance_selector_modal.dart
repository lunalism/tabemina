import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_locale_provider.dart';
import '../../../../core/providers/app_theme_mode_provider.dart';
import '../mypage_labels.dart';

/// Bottom sheet for picking the app's appearance: System / Light / Dark.
///
/// Mirrors [LanguageSelectorModal] in shape so the two settings feel
/// consistent — drag handle, title, list of rows with optional checkmark on
/// the active selection.
class AppearanceSelectorModal extends ConsumerWidget {
  const AppearanceSelectorModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const AppearanceSelectorModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final current = ref.watch(appThemeModeProvider);
    final lang = ref.watch(appLocaleProvider).languageCode;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: c.bgCard,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.spaceLg),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: AppConstants.spaceSm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin:
                  const EdgeInsets.only(top: 6, bottom: AppConstants.spaceMd),
              decoration: BoxDecoration(
                color: c.borderSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spaceLg,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  MyPageLabels.of(lang).appearanceLabel,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spaceSm),
            for (final mode in AppThemeMode.values)
              _ModeRow(
                mode: mode,
                selected: mode == current,
                lang: lang,
                onTap: () async {
                  await ref.read(appThemeModeProvider.notifier).set(mode);
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
            const SizedBox(height: AppConstants.spaceSm),
          ],
        ),
      ),
    );
  }
}

class _ModeRow extends StatelessWidget {
  const _ModeRow({
    required this.mode,
    required this.selected,
    required this.lang,
    required this.onTap,
  });

  final AppThemeMode mode;
  final bool selected;
  final String lang;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spaceLg,
          vertical: AppConstants.spaceMd,
        ),
        child: Row(
          children: [
            Icon(themeModeIcon(mode), size: 20, color: c.textPrimary),
            const SizedBox(width: AppConstants.spaceMd),
            Expanded(
              child: Text(
                themeModeDisplayName(mode, lang),
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                  color: c.textPrimary,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_rounded, size: 20, color: c.primary),
          ],
        ),
      ),
    );
  }
}
