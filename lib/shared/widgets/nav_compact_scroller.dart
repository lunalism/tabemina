import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/nav_compact_provider.dart';

/// Wraps a scrollable and drives [navCompactProvider] so the floating nav
/// shrinks on scroll-down and expands on scroll-up:
///   - near the top (≤16px) → expanded (compact = false);
///   - scrolling down (reverse) → compact;
///   - scrolling up (forward) → expanded.
///
/// Only the primary scrollable (`depth == 0`) drives it; the top threshold
/// keeps tiny scrolls from flickering. The bar never hides — only shrinks.
class NavCompactScroller extends ConsumerWidget {
  const NavCompactScroller({super.key, required this.child});

  final Widget child;

  /// At/below this offset the nav is always expanded.
  static const double _topThreshold = 16;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void setCompact(bool value) =>
        ref.read(navCompactProvider.notifier).set(value);

    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        if (notification.depth != 0) return false;
        if (notification.metrics.pixels <= _topThreshold) {
          setCompact(false);
        } else if (notification.direction == ScrollDirection.reverse) {
          setCompact(true);
        } else if (notification.direction == ScrollDirection.forward) {
          setCompact(false);
        }
        return false;
      },
      child: child,
    );
  }
}
