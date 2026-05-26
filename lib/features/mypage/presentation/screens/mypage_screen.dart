import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_locale_provider.dart';
import '../widgets/language_selector_modal.dart';

/// Minimal settings surface — guest header + a few system rows.
///
/// Sign-in, dark-mode preference, and full profile editing are placeholders
/// for now; this screen exists so the language selector has a home and so
/// users have a discoverable settings entry point.
class MyPageScreen extends ConsumerWidget {
  const MyPageScreen({super.key});

  static const String _appVersion = '1.0.0';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final locale = ref.watch(appLocaleProvider);

    return Scaffold(
      backgroundColor: c.bgPage,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(top: AppConstants.spaceXl),
          children: [
            const _GuestHeader(),
            const SizedBox(height: AppConstants.spaceXl),
            Divider(height: 1, thickness: 0.5, color: c.borderPrimary),
            const _SectionHeader(label: 'SETTINGS'),
            _SettingRow(
              icon: Icons.language_rounded,
              label: 'Language',
              trailing: localeDisplayName(locale),
              onTap: () => LanguageSelectorModal.show(context),
            ),
            _SettingRow(
              icon: Icons.dark_mode_outlined,
              label: 'Dark mode',
              trailing: 'System',
              onTap: () {},
            ),
            _SettingRow(
              icon: Icons.info_outline_rounded,
              label: 'Version',
              trailing: _appVersion,
              onTap: null,
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestHeader extends StatelessWidget {
  const _GuestHeader();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceLg),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: c.bgSkeleton,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.person_outline_rounded,
              size: 32,
              color: c.textTertiary,
            ),
          ),
          const SizedBox(width: AppConstants.spaceLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Guest User',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sign in to save your reviews',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 13,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spaceLg,
        AppConstants.spaceXl,
        AppConstants.spaceLg,
        AppConstants.spaceSm,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.8,
          color: c.textSecondary,
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String trailing;
  final VoidCallback? onTap;

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
            Icon(icon, size: 20, color: c.textPrimary),
            const SizedBox(width: AppConstants.spaceMd),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 15,
                  color: c.textPrimary,
                ),
              ),
            ),
            Text(
              trailing,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 13,
                color: c.textSecondary,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: c.textTertiary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
