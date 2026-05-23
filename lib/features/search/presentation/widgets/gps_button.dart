import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/location_providers.dart';

/// Floating "recenter on me" circle drawn over the map.
///
/// Requests location permission on tap, fetches the current position, and
/// animates the host map's camera there. Silently no-ops if location services
/// are off or permission was denied — that handling lives in
/// [locationServiceProvider]'s service.
class GpsButton extends ConsumerStatefulWidget {
  const GpsButton({
    super.key,
    required this.mapController,
    this.zoom = AppConstants.defaultMapZoom,
  });

  /// Completer wrapping the [GoogleMapController]. The host screen completes
  /// this in `onMapCreated`; the button awaits it so an early tap (before the
  /// map finishes initializing) still works.
  final Completer<GoogleMapController> mapController;

  /// Zoom level applied when recentering. Defaults to the app-wide map zoom.
  final double zoom;

  @override
  ConsumerState<GpsButton> createState() => _GpsButtonState();
}

class _GpsButtonState extends ConsumerState<GpsButton> {
  bool _busy = false;

  Future<void> _onPressed() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final position = await ref
          .read(locationServiceProvider)
          .getCurrentPosition();
      if (position == null || !mounted) return;
      final controller = await widget.mapController.future;
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: widget.zoom,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Material(
      color: c.bgCard,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: const Color(0x33000000),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _onPressed,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: _busy
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: c.textPrimary,
                    ),
                  )
                : Icon(Icons.my_location, size: 22, color: c.textPrimary),
          ),
        ),
      ),
    );
  }
}
