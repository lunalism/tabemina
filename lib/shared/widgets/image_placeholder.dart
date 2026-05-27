import 'package:flutter/material.dart';

/// Warm-gray plate with a camera glyph — used as the "before load" /
/// "error" surface for every network image in the app. Keeps the broken
/// state on-brand instead of falling through to Flutter's default broken
/// box.
class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 0,
    this.iconSize = 24,
    this.isError = false,
  });

  final double? width;
  final double? height;
  final double borderRadius;
  final double iconSize;

  /// `true` when shown after a network failure — swaps the camera glyph
  /// for `photo_off`. Same surface color so the layout doesn't shift
  /// between the load-start state and the load-failed state.
  final bool isError;

  // Two pairs of warm-gray tones, one set per theme — kept here (not in
  // AppColors) so widget callers don't have to remember which token maps
  // to "placeholder surface" vs "placeholder glyph". One job, one home.
  static const _bgLight = Color(0xFFF1EFE8);
  static const _bgDark = Color(0xFF2E2D28);
  static const _iconLight = Color(0xFFD3D1C7);
  static const _iconDark = Color(0xFF444441);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? _bgDark : _bgLight;
    final iconColor = isDark ? _iconDark : _iconLight;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: Icon(
        isError ? Icons.image_not_supported_outlined : Icons.photo_camera_outlined,
        size: iconSize,
        color: iconColor,
      ),
    );
  }
}
