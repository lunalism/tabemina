import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_locale_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../presentation/providers/auth_providers.dart';
import '../../../../shared/widgets/tabemina_snackbar.dart';
import '../account_deletion_labels.dart';
import '../providers/account_deletion_providers.dart';

/// Account-deletion confirmation screen (App Store Guideline 5.1.1(v)).
///
/// Reached from Settings → Delete account (signed-in only). Spells out the four
/// required disclosures, then offers a single destructive confirm + Cancel. On
/// confirm it stamps `pendingDeletionAt`, signs out to guest browsing, and
/// surfaces the 30-day notice. No type-to-confirm — one clear action.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  bool _busy = false;

  Future<void> _onConfirm(AccountDeletionLabels labels) async {
    // Guarded so repeat taps can't double-submit while the request is in flight
    // (the button is also disabled via `_busy`).
    if (_busy) return;
    setState(() => _busy = true);
    try {
      // Owner-write to pendingDeletionAt — must complete while still signed in.
      await ref.read(accountDeletionControllerProvider).requestDeletion();
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      showTabeminaSnackbar(context, message: labels.requestFailed);
      return;
    }
    if (!mounted) return;
    // Clean REPLACEMENT to public Home — clears the delete-account screen AND
    // the Settings sub-stack so nothing auth-gated lingers. Then surface the
    // notice on the Home scaffold (app-level messenger, survives the
    // tear-down). Sign out LAST so the auth flip can't race the router and
    // re-show this screen; we're already on a public route by then.
    context.go(AppRoutes.home);
    showTabeminaSnackbar(context, message: labels.requestedSnack);
    ref.read(authRepositoryProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final lang = ref.watch(appLocaleProvider).languageCode;
    final labels = AccountDeletionLabels.of(lang);

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
        title: Text(
          labels.screenTitle,
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.spaceXl,
                  AppConstants.spaceLg,
                  AppConstants.spaceXl,
                  AppConstants.spaceLg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: c.errorBg,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.person_remove_outlined,
                        color: c.errorText,
                        size: AppConstants.iconMd,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spaceLg),
                    Text(
                      labels.heading,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spaceLg),
                    _Point(text: labels.point1, c: c),
                    _Point(text: labels.point2, c: c),
                    _Point(text: labels.point3, c: c),
                    _Point(text: labels.point4, c: c),
                  ],
                ),
              ),
            ),
            // Action area pinned to the bottom, safe-area aware.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.spaceXl,
                AppConstants.spaceSm,
                AppConstants.spaceXl,
                AppConstants.spaceLg,
              ),
              child: Column(
                children: [
                  _DestructiveButton(
                    label: labels.confirmButton,
                    busy: _busy,
                    onTap: _busy ? null : () => _onConfirm(labels),
                  ),
                  const SizedBox(height: AppConstants.spaceSm),
                  _CancelButton(
                    label: labels.cancelButton,
                    onTap: _busy ? null : () => context.pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One disclosure bullet — a dot + wrapping text, ≥ comfortable line height.
class _Point extends StatelessWidget {
  const _Point({required this.text, required this.c});

  final String text;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spaceMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7, right: AppConstants.spaceMd),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: c.textTertiary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                height: 1.5,
                color: c.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Destructive confirm — red fill, label carries the meaning (not color alone).
class _DestructiveButton extends StatelessWidget {
  const _DestructiveButton({
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
          color: c.errorText,
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        ),
        alignment: Alignment.center,
        child: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

/// Secondary "Cancel" — quiet, ≥44px tap target.
class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
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
              color: c.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
