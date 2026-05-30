import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_locale_provider.dart';
import '../../../../core/providers/app_theme_mode_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../presentation/providers/auth_providers.dart';
import '../../../../presentation/providers/review_providers.dart';
import '../../../../shared/widgets/tabemina_snackbar.dart';
import '../../../mypage/presentation/mypage_labels.dart';
import '../../../mypage/presentation/widgets/appearance_selector_modal.dart';
import '../../../mypage/presentation/widgets/language_selector_modal.dart';

/// Dedicated Settings screen, reached from the My Page gear icon.
///
/// This is a pure relocation of the rows that used to live inline at the
/// bottom of My Page — same providers, same handlers, same auth-gated
/// visibility. Language / Appearance / Version are app-level (always shown);
/// Blocked users / Sign out require a signed-in user.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const String _appVersion = '1.0.0';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final locale = ref.watch(appLocaleProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final user = ref.watch(currentUserProvider);
    final lang = locale.languageCode;
    final labels = MyPageLabels.of(lang);

    return Scaffold(
      backgroundColor: c.bgPage,
      appBar: AppBar(
        backgroundColor: c.bgPage,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: c.textSecondary,
          ),
          onPressed: () => context.pop(),
        ),
        // Reuses the existing "Settings" string (settingsHeader) rather than
        // duplicating a new key.
        title: Text(
          labels.settingsHeader,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: c.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: AppConstants.spaceSm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              // Account-scoped rows — only for signed-in users (unchanged).
              if (user != null)
                _SettingRow(
                  icon: Icons.block_outlined,
                  label: labels.blockedUsers,
                  trailing: '',
                  onTap: () => context.push(AppRoutes.blockedUsers),
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
              ],
              const SizedBox(height: AppConstants.spaceXl),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signOut(
    BuildContext context,
    WidgetRef ref,
    MyPageLabels labels,
  ) async {
    // Drafts are per-account — drop the in-progress draft so it doesn't bleed
    // into the next user's session.
    await ref.read(draftStorageServiceProvider).clearDraft();
    ref.invalidate(hasDraftProvider);
    await ref.read(authRepositoryProvider).signOut();
    if (!context.mounted) return;
    showTabeminaSnackbar(context, message: labels.signedOutSnack);
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

  /// Fixed trailing slot so every chevron lands on the same x and every value
  /// right-aligns into the same column. A row without a chevron reserves the
  /// SAME width (empty) so its value doesn't drift to a different edge.
  static const double _chevronSlot = 24;

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
            // The ONLY flex child — fills all free space so the value +
            // chevron slot are pushed flush against the trailing edge.
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
            // Value is NON-flex (capped width) so it takes only what it needs
            // and short values don't reserve half the row. Long values
            // ellipsize within the cap and still right-align.
            if (trailing.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: AppConstants.spaceSm),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.4,
                  ),
                  child: Text(
                    trailing,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 13,
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ),
            // Reserved chevron slot (always present): chevron when the row
            // navigates, otherwise an empty box of the same width.
            SizedBox(
              width: _chevronSlot,
              child: onTap != null
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: c.textTertiary,
                      ),
                    )
                  : null,
            ),
          ],
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
