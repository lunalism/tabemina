import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/legal_constants.dart';
import '../../../../core/providers/app_locale_provider.dart';
import '../../../../core/providers/app_theme_mode_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../features/account_deletion/presentation/account_deletion_labels.dart';
import '../../../../features/eula/presentation/eula_labels.dart';
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
    // "Terms of Use" / "Privacy Policy" strings are owned by the EULA gate —
    // reused here rather than duplicated into MyPageLabels.
    final legal = EulaLabels.of(lang);

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
              // Legal & support — visible to everyone (guests included), since
              // Settings is reachable without auth. Terms / Privacy open in an
              // in-app browser sheet, so they keep the chevron; only Contact
              // leaves the app (mail composer) and carries the external glyph.
              _SectionHeader(label: labels.legalSupportHeader),
              _SettingRow(
                icon: Icons.description_outlined,
                label: legal.termsOfUse,
                trailing: '',
                onTap: () => _openUrl(
                  LegalConstants.legalUrlForLang(
                    LegalConstants.termsOfUseUrl,
                    lang,
                  ),
                ),
              ),
              _SettingRow(
                icon: Icons.privacy_tip_outlined,
                label: legal.privacyPolicy,
                trailing: '',
                onTap: () => _openUrl(
                  LegalConstants.legalUrlForLang(
                    LegalConstants.privacyPolicyUrl,
                    lang,
                  ),
                ),
              ),
              _SettingRow(
                icon: Icons.mail_outline_rounded,
                label: labels.contactLabel,
                trailing: '',
                opensExternally: true,
                onTap: () => _openContact(context),
              ),
              _SettingRow(
                icon: Icons.info_outline_rounded,
                label: labels.versionLabel,
                trailing: _appVersion,
                onTap: null,
              ),
              // Account-scoped rows — only for signed-in users.
              if (user != null) ...[
                _SettingRow(
                  icon: Icons.block_outlined,
                  label: labels.blockedUsers,
                  trailing: '',
                  onTap: () => context.push(AppRoutes.blockedUsers),
                ),
                // Destructive: red label + icon, but the literal "Delete
                // account" label is what conveys the action (not color alone).
                _SettingRow(
                  icon: Icons.person_remove_outlined,
                  label: AccountDeletionLabels.of(lang).rowLabel,
                  trailing: '',
                  destructive: true,
                  onTap: () => context.push(AppRoutes.deleteAccount),
                ),
              ],
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

  /// Open a hosted legal page in an in-app browser sheet (SFSafariViewController
  /// on iOS, Chrome Custom Tabs on Android) so the user stays in Tabemina and
  /// returns with Done / swipe. Swallowing failures is intentional — there's no
  /// useful recovery if the OS rejects the URL.
  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  }

  /// Open the mail composer to the support address. If no mail app can handle
  /// it, fall back to surfacing the address in the snackbar so the user can
  /// still note it down.
  Future<void> _openContact(BuildContext context) async {
    final uri = Uri.parse(LegalConstants.supportMailtoUrl());
    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }
    if (!launched && context.mounted) {
      showTabeminaSnackbar(context, message: LegalConstants.supportEmail);
    }
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
    this.opensExternally = false,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String trailing;
  final VoidCallback? onTap;

  /// When true, the trailing affordance is an external-link glyph
  /// (Icons.open_in_new) instead of the in-app chevron — signalling the row
  /// leaves the app. The icon carries the meaning; it isn't color-coded.
  final bool opensExternally;

  /// When true, the icon + label are tinted with the error color to flag a
  /// destructive action. Decoration only — the label text carries the meaning.
  final bool destructive;

  /// Fixed trailing slot so every chevron lands on the same x and every value
  /// right-aligns into the same column. A row without a chevron reserves the
  /// SAME width (empty) so its value doesn't drift to a different edge.
  static const double _chevronSlot = 24;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final labelColor = destructive ? c.errorText : c.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spaceLg,
          vertical: AppConstants.spaceMd,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: labelColor),
            const SizedBox(width: AppConstants.spaceMd),
            // The ONLY flex child — fills all free space so the value +
            // chevron slot are pushed flush against the trailing edge.
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 15,
                  color: labelColor,
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
            // Reserved trailing slot (always present, same width) so every
            // row's glyph lands in one column: a chevron for in-app rows, an
            // external-link glyph for rows that leave the app, or an empty box
            // for non-tappable rows.
            SizedBox(
              width: _chevronSlot,
              child: onTap != null
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: Icon(
                        opensExternally
                            ? Icons.open_in_new_rounded
                            : Icons.chevron_right_rounded,
                        size: opensExternally ? 18 : 20,
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

/// Small grouping header above a cluster of setting rows (e.g. "Legal &
/// support"). Quiet styling so it reads as a label, not a row.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spaceLg,
        AppConstants.spaceLg,
        AppConstants.spaceLg,
        AppConstants.spaceXs,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: c.textTertiary,
          letterSpacing: 0.3,
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
