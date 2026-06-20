import 'package:flutter/material.dart';

import 'image_placeholder.dart';
import 'shimmer_box.dart';

/// `Image.network` with a lightweight shimmer-while-loading and a 200ms
/// fade-in once the first frame decodes.
///
/// Loading pipeline:
/// - While loading: a single [ShimmerBox] occupies the slot (no extra
///   layers, no `Opacity`/`saveLayer` cost — that was the source of the
///   list-scroll slowdown).
/// - First frame ready: [AnimatedSwitcher] cross-fades shimmer → image
///   over [fadeInDuration]; the shimmer (and its AnimationController) is
///   removed from the tree once the fade completes.
/// - On error: [ImagePlaceholder] with the photo-off glyph.
///
/// Only one `Image.network` is created per photo. `frameBuilder` is the
/// framework-native "first frame ready" hook, so there's no second decode
/// for the placeholder.
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
    this.headers,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;

  /// Optional request headers for the underlying GET. Used by Places photo
  /// renders to send `X-Ios-Bundle-Identifier` so the request satisfies the
  /// Google Maps Platform key's iOS application restriction. Null for images
  /// that need no auth header (Firebase Storage, googleusercontent avatars).
  final Map<String, String>? headers;

  /// Override for the loading state. Defaults to a bare [ShimmerBox].
  final Widget? placeholder;

  /// Override for the error state. Defaults to [ImagePlaceholder] with the
  /// `image_not_supported` glyph.
  final Widget? errorPlaceholder;

  final double borderRadius;
  final double iconSize;
  final Duration fadeInDuration;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      headers: headers,
      width: width,
      height: height,
      fit: fit,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        // Already in the image cache — paint immediately, no shimmer, no
        // transition cost.
        if (wasSynchronouslyLoaded) return child;
        final loaded = frame != null;
        return AnimatedSwitcher(
          duration: fadeInDuration,
          child: loaded
              ? KeyedSubtree(
                  key: const ValueKey('image-loaded'),
                  child: child,
                )
              : (placeholder ??
                  ShimmerBox(
                    width: width,
                    height: height,
                    borderRadius: borderRadius,
                  )),
        );
      },
      errorBuilder: (_, _, _) =>
          errorPlaceholder ??
          ImagePlaceholder(
            width: width,
            height: height,
            borderRadius: borderRadius,
            iconSize: iconSize,
            isError: true,
          ),
    );
  }
}
