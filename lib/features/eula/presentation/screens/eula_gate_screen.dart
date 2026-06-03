import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/legal_constants.dart';
import '../../../../core/providers/app_locale_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/tabemina_snackbar.dart';
import '../eula_labels.dart';
import '../providers/eula_providers.dart';

/// One-time EULA consent gate (App Store Guideline 1.2), shown full-screen
/// right after sign-in for any authenticated user who hasn't accepted the
/// current [LegalConstants.eulaVersion].
///
/// Non-dismissible: [PopScope] blocks the Android back button and the iOS
/// left-edge swipe (the route is a [MaterialPage], which has no edge-swipe to
/// begin with). The only exits are Agree or Decline. Reached via a GoRouter
/// redirect, so there is no underlying screen to pop back to.
class EulaGateScreen extends ConsumerStatefulWidget {
  const EulaGateScreen({super.key});

  @override
  ConsumerState<EulaGateScreen> createState() => _EulaGateScreenState();
}

class _EulaGateScreenState extends ConsumerState<EulaGateScreen> {
  /// True while an Agree/Decline action is in flight — disables both buttons
  /// so a double-tap can't double-submit or race the redirect.
  bool _busy = false;

  Future<void> _openLegal(String baseUrl) async {
    final lang = ref.read(appLocaleProvider).languageCode;
    final uri = Uri.parse(LegalConstants.legalUrlForLang(baseUrl, lang));
    // In-app browser keeps the user inside the onboarding flow rather than
    // bouncing out to Safari. Failures are silently ignored — the user already
    // tapped and there's no useful recovery.
    await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  }

  Future<void> _onAgree(EulaLabels labels) async {
    setState(() => _busy = true);
    try {
      await ref.read(eulaConsentProvider.notifier).accept();
      if (!mounted) return;
      // Consent recorded — leave the gate. The redirect now allows /.
      context.go(AppRoutes.home);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      showTabeminaSnackbar(context, message: labels.saveFailed);
    }
  }

  Future<void> _onDecline() async {
    setState(() => _busy = true);
    // Clears local cache and signs out. The auth change rebuilds consent to
    // notRequired; we also navigate home explicitly so guest browsing resumes
    // immediately.
    await ref.read(eulaConsentProvider.notifier).decline();
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final lang = ref.watch(appLocaleProvider).languageCode;
    final labels = EulaLabels.of(lang);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: c.bgPage,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.space2xl,
                  vertical: AppConstants.space2xl,
                ),
                child: ConstrainedBox(
                  // Fill the viewport when there's room (so content can space
                  // out and buttons sit low) but allow growth + scroll on small
                  // screens / large Dynamic Type so nothing clips.
                  constraints: BoxConstraints(
                    minHeight:
                        constraints.maxHeight - AppConstants.space2xl * 2,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(),
                        _Header(c: c, labels: labels),
                        const SizedBox(height: AppConstants.space2xl),
                        Text(
                          labels.body,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 15,
                            height: 1.5,
                            color: c.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spaceLg),
                        _LegalLink(
                          label: labels.termsOfUse,
                          color: c.primary,
                          onTap: () => _openLegal(LegalConstants.termsOfUseUrl),
                        ),
                        _LegalLink(
                          label: labels.privacyPolicy,
                          color: c.primary,
                          onTap: () =>
                              _openLegal(LegalConstants.privacyPolicyUrl),
                        ),
                        const Spacer(flex: 2),
                        _PrimaryButton(
                          label: labels.agreeAndContinue,
                          busy: _busy,
                          onTap: _busy ? null : () => _onAgree(labels),
                        ),
                        const SizedBox(height: AppConstants.spaceSm),
                        _DeclineButton(
                          label: labels.decline,
                          color: c.textSecondary,
                          onTap: _busy ? null : _onDecline,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Brand wordmark + friendly handshake mark + welcome title.
class _Header extends StatelessWidget {
  const _Header({required this.c, required this.labels});

  final AppColors c;
  final EulaLabels labels;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: c.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.handshake_outlined,
            size: AppConstants.iconLg,
            color: c.primary,
          ),
        ),
        const SizedBox(height: AppConstants.spaceLg),
        const Text(
          'Tabemina',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppConstants.spaceXs),
        Text(
          labels.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Tappable legal-page link. Full-width row with a >=44px tap target and an
/// external-link affordance.
class _LegalLink extends StatelessWidget {
  const _LegalLink({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusSm),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
                decoration: TextDecoration.underline,
                decorationColor: color,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.open_in_new, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}

/// Primary "Agree and continue" action — Coral, full-width, >=44px tall.
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: c.primary,
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        ),
        alignment: Alignment.center,
        child: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.onPrimary,
                  ),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onPrimary,
                ),
              ),
      ),
    );
  }
}

/// Secondary "Decline" action. Conveyed by its label, not color (the gate
/// stays calm; declining signs the user out into guest browsing).
class _DeclineButton extends StatelessWidget {
  const _DeclineButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
