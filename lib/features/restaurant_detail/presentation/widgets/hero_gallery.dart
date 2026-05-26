import 'package:flutter/material.dart';

import '../../data/datasources/place_detail_remote_datasource.dart';

/// Photo carousel for the top of the detail screen.
///
/// Caps at 5 photos so the page-indicator row stays scannable; if the place
/// has zero photos, falls back to a neutral fork-knife placeholder that
/// matches the home card empty state.
///
/// Owns its own back button so the hero is the only thing layered over the
/// photo — no app bar, no title, no share action. The button is inset by the
/// status-bar height so it doesn't sit on the iOS notch / Dynamic Island.
class HeroGallery extends StatefulWidget {
  const HeroGallery({
    super.key,
    required this.photoNames,
    required this.onBack,
  });

  final List<String> photoNames;
  final VoidCallback onBack;

  static const int maxPhotos = 5;

  @override
  State<HeroGallery> createState() => _HeroGalleryState();
}

class _HeroGalleryState extends State<HeroGallery> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos =
        widget.photoNames.take(HeroGallery.maxPhotos).toList(growable: false);
    final hasPhotos = photos.isNotEmpty;
    final statusBar = MediaQuery.paddingOf(context).top;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasPhotos)
          PageView.builder(
            controller: _controller,
            itemCount: photos.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => _GalleryImage(photoName: photos[i]),
          )
        else
          const _Placeholder(),

        // Top gradient overlay so the back button + status bar icons stay
        // readable on bright photos.
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 80,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x4D000000), Color(0x00000000)],
                ),
              ),
            ),
          ),
        ),

        if (hasPhotos && photos.length > 1) ...[
          Positioned(
            bottom: 12,
            right: 12,
            child: _PhotoCounter(current: _page + 1, total: photos.length),
          ),
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: _PageDots(count: photos.length, active: _page),
          ),
        ],

        Positioned(
          top: statusBar + 8,
          left: 8,
          child: HeroBackButton(onTap: widget.onBack),
        ),
      ],
    );
  }
}

/// Translucent-black round back button used both inside [HeroGallery] and on
/// the loading / error states so the affordance stays put across all three.
class HeroBackButton extends StatelessWidget {
  const HeroBackButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x59000000),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 34,
          height: 34,
          child: Icon(Icons.arrow_back_rounded, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}

class _GalleryImage extends StatelessWidget {
  const _GalleryImage({required this.photoName});

  final String photoName;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      PlaceDetailRemoteDatasource.photoUrl(photoName, maxHeightPx: 1000),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const _Placeholder(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(color: const Color(0xFF1A1A18));
      },
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  // Same warm palette as the home card placeholder so the detail screen feels
  // continuous with the feed. Kept local rather than promoted to AppColors
  // because no other surface needs it.
  static const _gradient = [Color(0xFFF5F3EE), Color(0xFFEBE9E2)];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradient,
        ),
      ),
      alignment: Alignment.center,
      child: const Opacity(
        opacity: 0.3,
        child: Icon(Icons.restaurant, size: 48, color: Color(0xFF888780)),
      ),
    );
  }
}

class _PhotoCounter extends StatelessWidget {
  const _PhotoCounter({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0x80000000),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$current/$total',
        style: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: i == active ? 1.0 : 0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
