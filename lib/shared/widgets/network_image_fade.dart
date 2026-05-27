import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// `Image.network` with a built-in 200ms fade-in once the first frame
/// resolves, so list scrolling doesn't show a hard pop-in.
///
/// `frameBuilder` is the framework-native way to detect "first frame
/// available" without pulling in a third-party package (no
/// `transparent_image` dep needed). A grey skeleton fills the slot until
/// the image lands, and a callback-driven error builder shows the same
/// placeholder if the request fails.
class FadeInNetworkImage extends StatelessWidget {
  const FadeInNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorPlaceholder,
    this.fadeInDuration = const Duration(milliseconds: 200),
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorPlaceholder;
  final Duration fadeInDuration;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final defaultPlaceholder = Container(
      width: width,
      height: height,
      color: c.bgSkeleton,
    );
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      frameBuilder: (context, child, frame, wasSyncLoaded) {
        if (wasSyncLoaded) return child;
        // `frame == null` means the decoder hasn't produced the first
        // frame yet — show the placeholder. Once it does, AnimatedOpacity
        // fades the real image in.
        return AnimatedSwitcher(
          duration: fadeInDuration,
          child: frame == null
              ? (placeholder ?? defaultPlaceholder)
              : KeyedSubtree(
                  key: const ValueKey('image-loaded'),
                  child: child,
                ),
        );
      },
      errorBuilder: (_, _, _) =>
          errorPlaceholder ?? placeholder ?? defaultPlaceholder,
    );
  }
}
