import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/network_image_fade.dart';
import '../../domain/models/photo_upload_state.dart';
import 'section_label.dart';

/// Photo strip — add slot + filled slots showing each photo's pre-upload
/// state (processing / uploading % / completed / failed). State is owned by
/// the parent's PhotoUploadManager; this widget only renders and bubbles up
/// pick / remove / retry callbacks.
class PhotoSection extends StatelessWidget {
  const PhotoSection({
    super.key,
    required this.photos,
    required this.maxPhotos,
    required this.onPick,
    required this.onRemove,
    required this.onRetry,
    required this.l,
  });

  final List<PhotoUploadState> photos;
  final int maxPhotos;
  final VoidCallback onPick;
  final void Function(String localId) onRemove;
  final void Function(String localId) onRetry;
  final PhotoSectionLabels l;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final canAddMore = photos.length < maxPhotos;
    // When any photo can never be processed, swap the normal hint for a warm,
    // full-width (wrapping, size-safe) line pointing the user to remove it and
    // pick a different one — the escape from the otherwise-dead retry loop.
    final hasUnprocessable =
        photos.any((p) => p.failureKind == PhotoFailureKind.unprocessable);

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
                  _PhotoSlot(
                    // Stable identity so gaplessPlayback can't paint a stale
                    // image into a slot reused for a different photo after a
                    // remove/reorder.
                    key: ValueKey(photos[i].localId),
                    photo: photos[i],
                    isCover: i == 0,
                    coverLabel: l.cover,
                    onRemove: () => onRemove(photos[i].localId),
                    onRetry: () => onRetry(photos[i].localId),
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
              hasUnprocessable ? l.unprocessableHint : l.hint,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 11,
                color: hasUnprocessable ? c.warningText : c.textSecondary,
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
    required this.unprocessableHint,
  });

  final String title;
  final String requiredBadge;
  final String addPhoto;
  final String cover;
  final String hint;

  /// Shown in place of [hint] when a picked photo can never be processed —
  /// tells the user to remove it and choose a different one.
  final String unprocessableHint;
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({
    super.key,
    required this.photo,
    required this.isCover,
    required this.coverLabel,
    required this.onRemove,
    required this.onRetry,
  });

  final PhotoUploadState photo;
  final bool isCover;
  final String coverLabel;
  final VoidCallback onRemove;
  final VoidCallback onRetry;

  // Display dimensions of the slot. The decode-resolution cap is derived from
  // these (× devicePixelRatio) so the cap tracks the actual slot size rather
  // than being a hardcoded magic number.
  static const double _slotWidth = 80;
  static const double _slotHeight = 110;

  @override
  Widget build(BuildContext context) {
    // Cap the decoded bitmap to the slot's HEIGHT in device pixels. Single
    // dimension only — width is left to scale with the source aspect ratio so
    // BoxFit.cover stays crisp and undistorted (the portrait slot makes height
    // the binding dimension for landscape and standard-portrait sources).
    final cacheHeight =
        (_slotHeight * MediaQuery.devicePixelRatioOf(context)).round();
    return SizedBox(
      width: _slotWidth,
      height: _slotHeight,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _base(cacheHeight),
          ),
          // Status overlay (processing / uploading / failed).
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _overlay(context),
            ),
          ),
          if (isCover && photo.status == PhotoUploadStatus.completed)
            Positioned(
              left: 4,
              bottom: 4,
              child: _Badge(label: coverLabel),
            ),
          if (photo.status == PhotoUploadStatus.completed)
            const Positioned(right: 4, bottom: 4, child: _CompletedCheck()),
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
                  child:
                      Icon(Icons.close_rounded, size: 12, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _base(int cacheHeight) {
    if (photo.isExisting && photo.downloadUrl != null) {
      return FadeInNetworkImage(
        url: photo.downloadUrl!,
        width: _slotWidth,
        height: _slotHeight,
        // Persisted network thumbnail — capping is fine (no local-decode
        // concurrency to contend with).
        cacheHeight: cacheHeight,
        borderRadius: 8,
      );
    }
    // The processed file is the one that LINGERS in the image cache (up to 5 at
    // once), so cap ITS decode for the memory win. The transient processing
    // preview renders the original UNCAPPED for an instant first frame — a
    // ResizeImage scaled-decode batched behind the 5 concurrent compressions is
    // what delayed previews by ~2-3s. gaplessPlayback keeps the original frame
    // on screen while the processed file's (capped) decode swaps in.
    final processed = photo.processedFile;
    return Image.file(
      File(processed?.path ?? photo.originalFile.path),
      width: _slotWidth,
      height: _slotHeight,
      cacheHeight: processed != null ? cacheHeight : null,
      gaplessPlayback: true,
      fit: BoxFit.cover,
    );
  }

  Widget _overlay(BuildContext context) {
    switch (photo.status) {
      case PhotoUploadStatus.processing:
        return Container(
          color: const Color(0x66000000),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
        );
      case PhotoUploadStatus.uploading:
        return Container(
          color: const Color(0x66000000),
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                  value: photo.uploadProgress > 0 ? photo.uploadProgress : null,
                ),
              ),
              Text(
                '${(photo.uploadProgress * 100).round()}%',
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      case PhotoUploadStatus.failed:
        final c = AppColors.of(context);
        final unprocessable =
            photo.failureKind == PhotoFailureKind.unprocessable;
        // Warm terracotta wash (dark-mode-correct, same strong accent in both
        // modes with a cream icon) — replaces the old harsh brick-red literal.
        final wash = c.snackbarBlockedFill.withValues(alpha: 0.62);
        final fg = c.snackbarBlockedIcon;
        if (unprocessable) {
          // Never re-encodable → retry is pointless: no tap handler, and a
          // "can't use" glyph instead of the refresh icon. The X remove button
          // (rendered by the parent) is the way out; the hint line explains.
          return Container(
            color: wash,
            alignment: Alignment.center,
            child: Icon(Icons.broken_image_rounded, size: 24, color: fg),
          );
        }
        return Material(
          color: wash,
          child: InkWell(
            onTap: onRetry,
            child: Center(
              child: Icon(Icons.refresh_rounded, size: 24, color: fg),
            ),
          ),
        );
      case PhotoUploadStatus.completed:
        return const SizedBox.shrink();
    }
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0x80000000),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 9,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _CompletedCheck extends StatelessWidget {
  const _CompletedCheck();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.check_circle, size: 16, color: Color(0xFF2E9E5B)),
    );
  }
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

/// Coral dashed border used by the "Add photo" slot.
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
