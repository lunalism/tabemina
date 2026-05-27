import 'package:flutter/material.dart';

/// Animated shimmer rectangle — gradient sweep left-to-right on a 1.5s
/// linear loop. The base colors swap automatically by theme brightness so
/// callers don't need to thread a palette through.
///
/// Designed as the only loading affordance Tabemina uses (Tabemina ships
/// no spinners outside of pull-to-refresh). For circles, set
/// `borderRadius == width / 2` or use [ShimmerCircle].
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 4,
  });

  /// Convenience for square avatars / photo placeholders.
  const ShimmerBox.square({
    super.key,
    required double size,
    this.borderRadius = 4,
  })  : width = size,
        height = size;

  final double? width;
  final double? height;
  final double borderRadius;

  static const _lightStops = [
    Color(0xFFF1EFE8),
    Color(0xFFE8E6DF),
    Color(0xFFF1EFE8),
  ];

  static const _darkStops = [
    Color(0xFF2E2D28),
    Color(0xFF3A3935),
    Color(0xFF2E2D28),
  ];

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? ShimmerBox._darkStops : ShimmerBox._lightStops;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // Sweep the gradient from [-1, 0] off-screen left through [1, 2]
        // off-screen right — slightly extended endpoints so the brighter
        // mid-stop fully crosses the box width.
        final t = _controller.value;
        final begin = Alignment(-1 - 2 * (1 - t), 0);
        final end = Alignment(1 + 2 * t, 0);
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: begin,
              end: end,
              colors: colors,
            ),
          ),
        );
      },
    );
  }
}

/// Circular variant. Width and height are derived from [size]; the
/// borderRadius is set to size/2 so the result is a perfect circle.
class ShimmerCircle extends StatelessWidget {
  const ShimmerCircle({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ShimmerBox(width: size, height: size, borderRadius: size / 2);
  }
}
