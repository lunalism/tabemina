import 'package:flutter/material.dart';

/// Wraps a bookmark icon and plays a brief scale-bounce whenever [saved]
/// flips from false → true.
///
/// Listening to the prop change (instead of plumbing a callback through
/// `onTap`) keeps the animation in sync no matter where the toggle
/// originated — heart taps, swipe-and-save, future remote sync, all
/// produce the same pulse.
class BookmarkPulse extends StatefulWidget {
  const BookmarkPulse({
    super.key,
    required this.saved,
    required this.child,
  });

  final bool saved;
  final Widget child;

  @override
  State<BookmarkPulse> createState() => _BookmarkPulseState();
}

class _BookmarkPulseState extends State<BookmarkPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // 1.0 → 1.3 → 1.0 with elasticOut on the bounce-back for a springy
    // feel. weight 50/50 splits the 300ms duration evenly between the
    // grow and settle halves.
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.3),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.3, end: 1.0),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(covariant BookmarkPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only pulse on save (false → true). Removing a bookmark doesn't
    // get a celebratory animation per spec.
    if (!oldWidget.saved && widget.saved) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}
