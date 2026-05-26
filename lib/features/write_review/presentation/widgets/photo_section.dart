import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import 'section_label.dart';

/// Photo strip — add slot + filled slots with remove + Cover badge.
///
/// State (photo list, max count) is owned by the parent screen; this widget
/// only renders and bubbles up callbacks. Image compression happens at pick
/// time via [ImagePicker]'s `maxWidth`/`imageQuality`, so the parent only
/// has to track the resulting [XFile]s.
class PhotoSection extends StatelessWidget {
  const PhotoSection({
    super.key,
    required this.photos,
    required this.maxPhotos,
    required this.onPick,
    required this.onRemove,
    required this.l,
  });

  final List<XFile> photos;
  final int maxPhotos;
  final VoidCallback onPick;
  final void Function(int index) onRemove;
  final PhotoSectionLabels l;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final canAddMore = photos.length < maxPhotos;

    return Padding(
      padding: const EdgeInsets.only(top: AppConstants.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spaceLg,
            ),
            child: SectionLabel(
              icon: Icons.photo_camera_outlined,
              label: l.title,
              badgeText: l.requiredBadge,
              badgeRequired: true,
            ),
          ),
          const SizedBox(height: AppConstants.spaceSm),
          SizedBox(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spaceLg,
              ),
              children: [
                if (canAddMore) ...[
                  _AddSlot(label: l.addPhoto, onTap: onPick),
                  const SizedBox(width: AppConstants.spaceSm),
                ],
                for (int i = 0; i < photos.length; i++) ...[
                  _FilledSlot(
                    photo: photos[i],
                    isCover: i == 0,
                    coverLabel: l.cover,
                    onRemove: () => onRemove(i),
                  ),
                  if (i < photos.length - 1)
                    const SizedBox(width: AppConstants.spaceSm),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spaceLg,
            ),
            child: Text(
              l.hint,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 11,
                color: c.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PhotoSectionLabels {
  const PhotoSectionLabels({
    required this.title,
    required this.requiredBadge,
    required this.addPhoto,
    required this.cover,
    required this.hint,
  });

  final String title;
  final String requiredBadge;
  final String addPhoto;
  final String cover;
  final String hint;
}

class _AddSlot extends StatelessWidget {
  const _AddSlot({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: DottedBorder(
        color: c.primary,
        radius: 10,
        child: SizedBox(
          width: 100,
          height: 110,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo_camera_rounded, size: 28, color: c.primary),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: c.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilledSlot extends StatelessWidget {
  const _FilledSlot({
    required this.photo,
    required this.isCover,
    required this.coverLabel,
    required this.onRemove,
  });

  final XFile photo;
  final bool isCover;
  final String coverLabel;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 110,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(photo.path),
              width: 80,
              height: 110,
              fit: BoxFit.cover,
            ),
          ),
          if (isCover)
            Positioned(
              left: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0x80000000),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  coverLabel,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: const Color(0x80000000),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: const SizedBox(
                  width: 18,
                  height: 18,
                  child: Icon(Icons.close_rounded, size: 12, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Coral dashed border used by the "Add photo" slot.
///
/// Flutter doesn't ship a dashed border out of the box, so a custom painter
/// draws the rounded-rect outline. Kept private to the photo section since
/// it's the only consumer.
class DottedBorder extends StatelessWidget {
  const DottedBorder({
    super.key,
    required this.color,
    required this.radius,
    required this.child,
  });

  final Color color;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(color: color, radius: radius),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(radius),
      ));

    const dash = 5.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
