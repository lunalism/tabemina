import 'package:flutter/material.dart';

import 'image_placeholder.dart';
import 'shimmer_box.dart';

/// `Image.network` with a built-in 200ms fade-in once the first frame
/// resolves, so list scrolling doesn't show a hard pop-in.
///
/// Loading pipeline (matches the rest of the app):
/// - Before decode: warm-gray plate with camera glyph ([ImagePlaceholder]).
/// - During load: [ShimmerBox] overlay on the same plate.
/// - On error: [ImagePlaceholder] with `isError: true` (photo-off glyph).
/// - On success: cross-fade from the placeholder to the decoded image.
///
/// `frameBuilder` is the framework-native way to detect "first frame
/// available" without pulling in a third-party package (no
/// `transparent_image` dep needed).
class FadeInNetworkImage extends StatelessWidget {
  const FadeInNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorPlaceholder,
    this.borderRadius = 0,
    this.iconSize = 24,
    this.fadeInDuration = const Duration(milliseconds: 200),
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;

  /// Override for the loading state. Defaults to [ImagePlaceholder] with
  /// a shimmer overlay; pass your own widget for surfaces with bespoke
  /// chrome (e.g. the hero gallery's dark background).
  final Widget? placeholder;

  /// Override for the error state. Defaults to [ImagePlaceholder] with
  /// the `image_not_supported` glyph at the same surface color.
  final Widget? errorPlaceholder;

  /// Border radius applied to the default placeholders. Ignored if a
  /// custom [placeholder] / [errorPlaceholder] is provided.
  final double borderRadius;

  /// Icon size for the default placeholders. The hero gallery uses 48px;
  /// thumbnails 20–24px.
  final double iconSize;

  final Duration fadeInDuration;

  Widget _defaultPlaceholder({required bool isError}) {
    final base = ImagePlaceholder(
      width: width,
      height: height,
      borderRadius: borderRadius,
      iconSize: iconSize,
      isError: isError,
    );
    if (isError) return base;
    // Shimmer overlays the plate while we're actively loading — the icon
    // shows through faintly so the slot still reads as an image.
    return Stack(
      fit: StackFit.passthrough,
      children: [
        base,
        Positioned.fill(
          child: Opacity(
            opacity: 0.7,
            child: ShimmerBox(
              width: width,
              height: height,
              borderRadius: borderRadius,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      frameBuilder: (context, child, frame, wasSyncLoaded) {
        if (wasSyncLoaded) return child;
        return AnimatedSwitcher(
          duration: fadeInDuration,
          child: frame == null
              ? (placeholder ?? _defaultPlaceholder(isError: false))
              : KeyedSubtree(
                  key: const ValueKey('image-loaded'),
                  child: child,
                ),
        );
      },
      errorBuilder: (_, _, _) =>
          errorPlaceholder ?? _defaultPlaceholder(isError: true),
    );
  }
}
