import 'package:flutter/material.dart';

/// Color tokens for Tabemina — warm Coral palette.
///
/// Tokens are defined as light/dark pairs and resolved per-context through
/// [AppColors.of], so widgets can write `AppColors.of(context).primary`
/// instead of branching on `Theme.of(context).brightness`. Static aliases on
/// [AppColors] resolve to the *light* value; use them only in places that have
/// no [BuildContext] (e.g. brand splash where both modes are intentionally the
/// same).
@immutable
class AppColors {
  const AppColors._({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.bgPage,
    required this.bgCard,
    required this.bgSkeleton,
    required this.bgSecondary,
    required this.borderPrimary,
    required this.borderSecondary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.successBg,
    required this.successText,
    required this.errorBg,
    required this.errorText,
    required this.warningBg,
    required this.warningText,
    required this.infoBg,
    required this.infoText,
    required this.tabActive,
    required this.tabInactive,
    required this.snackbarBg,
    required this.snackbarText,
  });

  // Primary palette
  final Color primary;
  final Color secondary;
  final Color accent;

  // Neutrals
  final Color bgPage;
  final Color bgCard;
  final Color bgSkeleton;
  final Color bgSecondary;
  final Color borderPrimary;
  final Color borderSecondary;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  // Semantic
  final Color successBg;
  final Color successText;
  final Color errorBg;
  final Color errorText;
  final Color warningBg;
  final Color warningText;
  final Color infoBg;
  final Color infoText;

  // Tabs
  final Color tabActive;
  final Color tabInactive;

  // Snackbar (intentionally dark in both modes — the surface needs to read
  // as a transient overlay against page content, not blend into it).
  final Color snackbarBg;
  final Color snackbarText;

  /// Foreground placed on top of the Coral primary in both modes.
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Brand Coral, identical in both modes — for surfaces (splash, FAB) that
  /// should read as Coral regardless of theme.
  static const Color brandCoralLight = Color(0xFFE8593C);
  static const Color brandCoralDark = Color(0xFFFF8C66);

  /// Light theme tokens.
  static const AppColors light = AppColors._(
    primary: Color(0xFFE8593C),
    secondary: Color(0xFFF5B85C),
    accent: Color(0xFF1A9E75),
    bgPage: Color(0xFFFFFBF5),
    bgCard: Color(0xFFFFFFFF),
    bgSkeleton: Color(0xFFF1EFE8),
    bgSecondary: Color(0xFFF8F7F2),
    borderPrimary: Color(0xFFE8E6DF),
    borderSecondary: Color(0xFFD3D1C7),
    textPrimary: Color(0xFF1A1A18),
    textSecondary: Color(0xFF888780),
    textTertiary: Color(0xFFB4B2A9),
    successBg: Color(0xFFE1F5EE),
    successText: Color(0xFF085041),
    errorBg: Color(0xFFFCEBEB),
    errorText: Color(0xFF791F1F),
    warningBg: Color(0xFFFAEEDA),
    warningText: Color(0xFF633806),
    infoBg: Color(0xFFE6F1FB),
    infoText: Color(0xFF0C447C),
    tabActive: Color(0xFFE8593C),
    tabInactive: Color(0xFF888780),
    snackbarBg: Color(0xF23D3A36),
    snackbarText: Color(0xFFFAFAF8),
  );

  /// Dark theme tokens. Tinted backgrounds for semantic states are expressed
  /// at 12% alpha over the corresponding accent.
  static AppColors dark = AppColors._(
    primary: const Color(0xFFFF8C66),
    secondary: const Color(0xFFF5B85C),
    accent: const Color(0xFF5DCAA5),
    bgPage: const Color(0xFF1C1B18),
    bgCard: const Color(0xFF252420),
    bgSkeleton: const Color(0xFF2E2D28),
    bgSecondary: const Color(0xFF2A2924),
    borderPrimary: const Color(0xFF444441),
    borderSecondary: const Color(0xFF3A3935),
    textPrimary: const Color(0xFFE8E6DF),
    textSecondary: const Color(0xFF888780),
    textTertiary: const Color(0xFF666660),
    // 0.12 alpha tints over their respective accents.
    successBg: const Color(0x1F1A9E75),
    successText: const Color(0xFF9FE1CB),
    errorBg: const Color(0x1FE24B4A),
    errorText: const Color(0xFFF0997B),
    warningBg: const Color(0x1FF5B85C),
    warningText: const Color(0xFFF5B85C),
    infoBg: const Color(0x1F4285F4),
    infoText: const Color(0xFF7BAAF0),
    tabActive: const Color(0xFFFF8C66),
    tabInactive: const Color(0xFF666660),
    snackbarBg: const Color(0xF23D3D3A),
    snackbarText: const Color(0xFFFAFAF8),
  );

  /// Resolve the right token set for the current theme brightness.
  static AppColors of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}
