import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_locale_provider.dart';

/// Bottom-sheet picker for the app language.
///
/// Each supported locale renders as a row [flag + name + optional checkmark].
/// Tapping a row updates [appLocaleProvider] (which persists the choice to
/// SharedPreferences) and dismisses the sheet. Closing without a tap leaves
/// the existing selection untouched.
class LanguageSelectorModal extends ConsumerWidget {
  const LanguageSelectorModal({super.key});

  /// Show the modal. Helper kept here so the trigger site doesn't need to
  /// know the sheet's shape / rounding values.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const LanguageSelectorModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final current = ref.watch(appLocaleProvider);

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: c.bgCard,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.spaceLg),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: AppConstants.spaceSm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle.
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 6, bottom: AppConstants.spaceMd),
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
                  'Language',
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
            for (final locale in kSupportedLocales)
              _LocaleRow(
                locale: locale,
                selected: locale.languageCode == current.languageCode,
                onTap: () async {
                  await ref.read(appLocaleProvider.notifier).set(locale);
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

class _LocaleRow extends StatelessWidget {
  const _LocaleRow({
    required this.locale,
    required this.selected,
    required this.onTap,
  });

  final Locale locale;
  final bool selected;
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
            Text(
              localeFlagEmoji(locale),
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: AppConstants.spaceMd),
            Expanded(
              child: Text(
                localeDisplayName(locale),
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
