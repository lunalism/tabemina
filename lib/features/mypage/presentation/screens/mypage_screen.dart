import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_locale_provider.dart';
import '../../../../core/providers/app_theme_mode_provider.dart';
import '../../../../domain/entities/user_entity.dart';
import '../../../../presentation/providers/auth_providers.dart';
import '../../../../presentation/widgets/login_bottom_sheet.dart';
import '../../../../shared/widgets/tabemina_snackbar.dart';
import '../widgets/appearance_selector_modal.dart';
import '../widgets/language_selector_modal.dart';

/// My Page — profile header (signed-in or guest CTA) + system settings.
///
/// Language and appearance stay visible regardless of auth state so guest
/// users can still personalize the app.
class MyPageScreen extends ConsumerWidget {
  const MyPageScreen({super.key});

  static const String _appVersion = '1.0.0';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final locale = ref.watch(appLocaleProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final user = ref.watch(currentUserProvider);
    final lang = locale.languageCode;
    final labels = _MyPageLabels.of(lang);

    return Scaffold(
      backgroundColor: c.bgPage,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(top: AppConstants.spaceXl),
          children: [
            if (user != null)
              _SignedInHeader(user: user, labels: labels)
            else
              _GuestSection(labels: labels),
            const SizedBox(height: AppConstants.spaceXl),
            Divider(height: 1, thickness: 0.5, color: c.borderPrimary),
            _SectionHeader(label: labels.settingsHeader),
            _SettingRow(
              icon: Icons.language_rounded,
              label: labels.languageLabel,
              trailing: localeDisplayName(locale),
              onTap: () => LanguageSelectorModal.show(context),
            ),
            _SettingRow(
              icon: Icons.brightness_6_outlined,
              label: labels.appearanceLabel,
              trailing: themeModeDisplayName(themeMode, lang),
              onTap: () => AppearanceSelectorModal.show(context),
            ),
            _SettingRow(
              icon: Icons.info_outline_rounded,
              label: labels.versionLabel,
              trailing: _appVersion,
              onTap: null,
            ),
            if (user != null) ...[
              const SizedBox(height: AppConstants.spaceLg),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spaceLg,
                ),
                child: _SignOutButton(
                  label: labels.signOut,
                  onTap: () => _signOut(context, ref, labels),
                ),
              ),
              const SizedBox(height: AppConstants.spaceXl),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _signOut(
    BuildContext context,
    WidgetRef ref,
    _MyPageLabels labels,
  ) async {
    await ref.read(authRepositoryProvider).signOut();
    if (!context.mounted) return;
    showTabeminaSnackbar(context, message: labels.signedOutSnack);
  }
}

class _SignedInHeader extends StatelessWidget {
  const _SignedInHeader({required this.user, required this.labels});

  final UserEntity user;
  final _MyPageLabels labels;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final photoUrl = user.photoUrl;
    final initials = _initialsOf(user);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceLg),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: c.bgSkeleton,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? Text(
                    initials,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AppConstants.spaceLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName?.isNotEmpty == true
                      ? user.displayName!
                      : labels.fallbackName,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                  ),
                ),
                if (user.email != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    user.email!,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 13,
                      color: c.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initialsOf(UserEntity user) {
    final name = user.displayName ?? user.email ?? '';
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}

class _GuestSection extends ConsumerWidget {
  const _GuestSection({required this.labels});

  final _MyPageLabels labels;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
                      labels.guestTitle,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels.guestSubtitle,
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
          const SizedBox(height: AppConstants.spaceLg),
          _InlineSignInButton(
            label: labels.signIn,
            onTap: () => showLoginBottomSheet(context),
          ),
        ],
      ),
    );
  }
}

class _InlineSignInButton extends StatelessWidget {
  const _InlineSignInButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: c.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.onPrimary,
          ),
        ),
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          border: Border.all(color: c.borderPrimary, width: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: c.textPrimary,
          ),
        ),
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

class _MyPageLabels {
  const _MyPageLabels({
    required this.guestTitle,
    required this.guestSubtitle,
    required this.signIn,
    required this.signOut,
    required this.signedOutSnack,
    required this.fallbackName,
    required this.settingsHeader,
    required this.languageLabel,
    required this.appearanceLabel,
    required this.versionLabel,
  });

  final String guestTitle;
  final String guestSubtitle;
  final String signIn;
  final String signOut;
  final String signedOutSnack;
  final String fallbackName;
  final String settingsHeader;
  final String languageLabel;
  final String appearanceLabel;
  final String versionLabel;

  static _MyPageLabels of(String lang) {
    switch (lang) {
      case 'ja':
        return const _MyPageLabels(
          guestTitle: 'ゲストユーザー',
          guestSubtitle: 'プロフィールにアクセスするにはログインしてください',
          signIn: 'ログイン',
          signOut: 'ログアウト',
          signedOutSnack: 'ログアウトしました',
          fallbackName: 'Tabemina ユーザー',
          settingsHeader: '設定',
          languageLabel: '言語',
          appearanceLabel: 'テーマ',
          versionLabel: 'バージョン',
        );
      case 'ko':
        return const _MyPageLabels(
          guestTitle: '게스트 사용자',
          guestSubtitle: '프로필에 접근하려면 로그인하세요',
          signIn: '로그인',
          signOut: '로그아웃',
          signedOutSnack: '로그아웃했습니다',
          fallbackName: 'Tabemina 사용자',
          settingsHeader: '설정',
          languageLabel: '언어',
          appearanceLabel: '테마',
          versionLabel: '버전',
        );
      case 'en':
      default:
        return const _MyPageLabels(
          guestTitle: 'Guest User',
          guestSubtitle: 'Sign in to access your profile',
          signIn: 'Sign in',
          signOut: 'Sign out',
          signedOutSnack: 'Signed out',
          fallbackName: 'Tabemina user',
          settingsHeader: 'SETTINGS',
          languageLabel: 'Language',
          appearanceLabel: 'Appearance',
          versionLabel: 'Version',
        );
    }
  }
}
