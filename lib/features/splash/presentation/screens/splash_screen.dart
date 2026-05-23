import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';

/// In-app animated splash.
///
/// Sits on top of the native (OS-level) splash so the brand-Coral background is
/// seamless across the hand-off. Fades the wordmark in, runs any startup work,
/// then routes to home. Identical in light and dark mode by design.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  /// Total time the splash stays visible before routing to home.
  static const Duration _minDisplay = Duration(seconds: 2);

  /// Delay before the text begins fading in.
  static const Duration _fadeDelay = Duration(milliseconds: 200);

  late final AnimationController _controller;
  late final Animation<double> _fade;
  Timer? _fadeTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    // Defer all timing to the first painted frame. On a cold start the engine
    // can take a few hundred ms to produce its first frame; if we started the
    // delay from initState, the whole 200ms + 300ms animation could finish
    // before anything is drawn, so the first visible frame would already be at
    // opacity 1 (no perceptible fade). Anchoring to the first frame guarantees
    // the user actually sees the fade-in.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onFirstFrame();
    });
  }

  void _onFirstFrame() {
    // Start the fade-in after a short delay.
    _fadeTimer = Timer(_fadeDelay, () {
      if (mounted) _controller.forward();
    });
    _bootstrap();
  }

  /// Runs startup work, then routes to home once the minimum display time has
  /// elapsed. Async init (Firebase warm-up, location permissions, etc.) can be
  /// awaited here later; for now it's a placeholder delay that overlaps the
  /// minimum display window rather than adding to it.
  Future<void> _bootstrap() async {
    await Future.wait([
      Future<void>.delayed(_minDisplay),
      _initServices(),
    ]);
    if (mounted) context.go(AppRoutes.home);
  }

  /// Placeholder for future async initialization.
  Future<void> _initServices() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _fadeTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Force light status bar icons over the Coral background, in both themes.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.brandCoralLight,
        body: Center(
          child: FadeTransition(
            opacity: _fade,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Tabemina',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    fontSize: 32,
                  ),
                ),
                SizedBox(height: 8),
                Opacity(
                  opacity: 0.8,
                  child: Text(
                    '食べみな',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w400,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
