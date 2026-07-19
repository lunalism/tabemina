import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Initials fallback text for [InitialsAvatar]: first character of the first
/// and last whitespace-separated words, uppercased ("Taro Yamada" → "TY"),
/// a single character for one-word names, '?' for empty / whitespace-only.
/// Grapheme-cluster aware via `characters`, so emoji and combined Hangul are
/// safe; `toUpperCase` is a no-op for CJK.
String initialsOf(String name) {
  final t = name.trim();
  if (t.isEmpty) return '?';
  final parts = t.split(RegExp(r'\s+'));
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return (parts.first.characters.first + parts.last.characters.first)
      .toUpperCase();
}

/// Circular avatar with an initials fallback.
///
/// Shows [photoUrl] when present; falls back to the [fallback] initials when
/// the URL is null/empty OR the network load fails (stale googleusercontent /
/// Places author URLs 404 routinely), instead of a blank grey circle.
/// In-memory image only — no disk caching on purpose: avatar sources
/// (Places authors, Firebase Storage user photos) are small and short-lived.
class InitialsAvatar extends StatefulWidget {
  const InitialsAvatar({
    super.key,
    required this.photoUrl,
    required this.fallback,
    this.radius = 14,
  });

  final String? photoUrl;
  final String fallback;
  final double radius;

  @override
  State<InitialsAvatar> createState() => _InitialsAvatarState();
}

class _InitialsAvatarState extends State<InitialsAvatar> {
  /// Set when the network image fails to load (e.g. a stale googleusercontent
  /// URL 404s) so the initials fallback replaces the blank circle.
  bool _failed = false;

  @override
  void didUpdateWidget(InitialsAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.photoUrl != oldWidget.photoUrl) _failed = false;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final url = widget.photoUrl;
    final showImage = !_failed && url != null && url.isNotEmpty;
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: c.bgSkeleton,
      backgroundImage: showImage ? NetworkImage(url) : null,
      onBackgroundImageError: showImage
          ? (_, _) {
              if (mounted) setState(() => _failed = true);
            }
          : null,
      child: showImage
          ? null
          : Text(
              widget.fallback,
              style: TextStyle(
                fontFamily: 'Pretendard',
                // Scales with the radius so non-default sizes keep the same
                // proportions as the original 11px-at-radius-14 design.
                fontSize: widget.radius * (11 / 14),
                fontWeight: FontWeight.w500,
                color: c.textPrimary,
                height: 1.0,
              ),
            ),
    );
  }
}
