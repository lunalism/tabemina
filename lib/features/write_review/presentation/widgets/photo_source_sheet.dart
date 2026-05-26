import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// Bottom sheet that asks "Camera or Gallery?" before [ImagePicker] runs.
///
/// Resolves to the chosen [ImageSource], or `null` if the user dismissed.
class PhotoSourceSheet {
  static Future<ImageSource?> show(
    BuildContext context, {
    required String cameraLabel,
    required String galleryLabel,
  }) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SheetContent(
        cameraLabel: cameraLabel,
        galleryLabel: galleryLabel,
      ),
    );
  }
}

class _SheetContent extends StatelessWidget {
  const _SheetContent({required this.cameraLabel, required this.galleryLabel});

  final String cameraLabel;
  final String galleryLabel;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: c.bgCard,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.spaceLg),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: AppConstants.spaceSm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 6, bottom: 6),
              decoration: BoxDecoration(
                color: c.borderSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _Row(
              icon: Icons.photo_camera_rounded,
              label: cameraLabel,
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            _Row(
              icon: Icons.photo_library_outlined,
              label: galleryLabel,
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            const SizedBox(height: AppConstants.spaceSm),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spaceLg,
          vertical: AppConstants.spaceMd,
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: c.textPrimary),
            const SizedBox(width: AppConstants.spaceMd),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 15,
                color: c.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
