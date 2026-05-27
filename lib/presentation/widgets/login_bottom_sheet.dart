import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/app_locale_provider.dart';
import '../../domain/entities/user_entity.dart';
import '../../shared/widgets/tabemina_snackbar.dart';
import '../providers/auth_providers.dart';

/// Slide-up login sheet shown when a guest taps a protected action
/// (write-review / bookmark). Returns the [UserEntity] on success, `null` on
/// cancel or failure.
Future<UserEntity?> showLoginBottomSheet(BuildContext context) {
  return showModalBottomSheet<UserEntity?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const LoginBottomSheet(),
  );
}

class LoginBottomSheet extends ConsumerStatefulWidget {
  const LoginBottomSheet({super.key});

  @override
  ConsumerState<LoginBottomSheet> createState() => _LoginBottomSheetState();
}

class _LoginBottomSheetState extends ConsumerState<LoginBottomSheet> {
  bool _busy = false;

  Future<void> _signInWith(_Provider provider) async {
    if (_busy) return;
    setState(() => _busy = true);

    final repo = ref.read(authRepositoryProvider);
    final lang = ref.read(appLocaleProvider).languageCode;
    final labels = _LoginLabels.of(lang);

    UserEntity? user;
    String? errorMessage;
    try {
      user = await switch (provider) {
        _Provider.google => repo.signInWithGoogle(),
        _Provider.apple => repo.signInWithApple(),
      };
    } catch (e, stackTrace) {
      debugPrint('LoginBottomSheet sign-in ERROR ($provider): $e');
      debugPrint('Stack trace: $stackTrace');
      errorMessage = labels.errorMessage;
    }

    if (!mounted) return;

    if (user != null) {
      // Pop with the signed-in user so the caller can resume the original
      // action (e.g. open write-review) only on successful sign-in.
      Navigator.of(context).pop(user);
      // Snackbar is queued on the parent scaffold's messenger, so it stays
      // visible after the sheet closes.
      showTabeminaSnackbar(context, message: labels.successMessage);
      return;
    }

    setState(() => _busy = false);
    if (errorMessage != null) {
      showTabeminaSnackbar(context, message: errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final lang = ref.watch(appLocaleProvider).languageCode;
    final labels = _LoginLabels.of(lang);

    return Container(
      decoration: BoxDecoration(
        color: c.bgCard,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.spaceXl,
            AppConstants.spaceMd,
            AppConstants.spaceXl,
            AppConstants.spaceLg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grabber bar.
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppConstants.spaceLg),
                decoration: BoxDecoration(
                  color: c.borderSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Tabemina',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: c.primary,
                ),
              ),
              const SizedBox(height: AppConstants.spaceSm),
              Text(
                labels.prompt,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 14,
                  color: c.textSecondary,
                ),
              ),
              const SizedBox(height: AppConstants.space2xl),
              _GoogleButton(
                label: labels.continueWithGoogle,
                onTap: _busy ? null : () => _signInWith(_Provider.google),
              ),
              const SizedBox(height: 12),
              _AppleButton(
                label: labels.continueWithApple,
                onTap: _busy ? null : () => _signInWith(_Provider.apple),
              ),
              const SizedBox(height: AppConstants.spaceLg),
              Text(
                labels.terms,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 12,
                  color: c.textTertiary,
                ),
              ),
              // No in-line spinner — the disabled button color
              // already reads as "working" while the OAuth round-trip
              // is happening. Tabemina ships no CircularProgressIndicator
              // outside of pull-to-refresh.
            ],
          ),
        ),
      ),
    );
  }
}

enum _Provider { google, apple }

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: c.borderPrimary, width: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _GoogleGlyph(),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F1F1F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppleButton extends StatelessWidget {
  const _AppleButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.apple, size: 22, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Multicolor "G" mark drawn with a CustomPainter — avoids shipping an asset
/// just for the brand glyph. Colors match Google's 2015+ brand guidelines.
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _GoogleGlyphPainter()),
    );
  }
}

class _GoogleGlyphPainter extends CustomPainter {
  const _GoogleGlyphPainter();

  // Approximate Google G logo using arc strokes + the inner horizontal stub.
  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1.5;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.butt;

    // 4 arc segments: blue (top-right), red (top), yellow (left), green (bottom)
    canvas.drawArc(rect, -0.55, 1.10, false, stroke..color = _blue);
    canvas.drawArc(rect, -1.65, 1.10, false, stroke..color = _red);
    canvas.drawArc(rect, -3.05, 1.40, false, stroke..color = _yellow);
    canvas.drawArc(rect, 1.55, 1.50, false, stroke..color = _green);

    // The horizontal "bar" of the G — short stub from the right-edge inward.
    final bar = Paint()
      ..color = _blue
      ..style = PaintingStyle.fill;
    final barRect = Rect.fromLTWH(
      center.dx,
      center.dy - 1.4,
      radius - 0.5,
      2.8,
    );
    canvas.drawRect(barRect, bar);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LoginLabels {
  const _LoginLabels({
    required this.prompt,
    required this.continueWithGoogle,
    required this.continueWithApple,
    required this.terms,
    required this.successMessage,
    required this.errorMessage,
  });

  final String prompt;
  final String continueWithGoogle;
  final String continueWithApple;
  final String terms;
  final String successMessage;
  final String errorMessage;

  static _LoginLabels of(String lang) {
    switch (lang) {
      case 'ja':
        return const _LoginLabels(
          prompt: 'お気に入りの保存やレビューの投稿にはログインが必要です',
          continueWithGoogle: 'Googleで続ける',
          continueWithApple: 'Appleで続ける',
          terms: '続行することで、利用規約に同意したものとみなされます',
          successMessage: 'ログインしました',
          errorMessage: 'ログインに失敗しました',
        );
      case 'ko':
        return const _LoginLabels(
          prompt: '즐겨찾기 저장과 리뷰 작성을 위해 로그인해주세요',
          continueWithGoogle: 'Google로 계속하기',
          continueWithApple: 'Apple로 계속하기',
          terms: '계속하면 서비스 이용약관에 동의하는 것으로 간주됩니다',
          successMessage: '로그인했습니다',
          errorMessage: '로그인에 실패했습니다',
        );
      case 'en':
      default:
        return const _LoginLabels(
          prompt: 'Sign in to save your favorites and write reviews',
          continueWithGoogle: 'Continue with Google',
          continueWithApple: 'Continue with Apple',
          terms: 'By continuing, you agree to our Terms of Service',
          successMessage: 'Signed in successfully',
          errorMessage: 'Sign-in failed',
        );
    }
  }
}
