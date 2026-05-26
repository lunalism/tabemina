import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// Compact non-interactive map showing the restaurant's location.
///
/// Lite mode keeps it cheap (no gesture handling, single bitmap render) and
/// also picks up the system's dark map style automatically on supported
/// platforms. Tap forwards to [onTap] so the parent can launch the full
/// Google Maps app with directions.
class MiniMap extends StatelessWidget {
  const MiniMap({
    super.key,
    required this.lat,
    required this.lng,
    required this.placeId,
    required this.onTap,
  });

  final double lat;
  final double lng;
  final String placeId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final position = LatLng(lat, lng);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spaceLg,
        AppConstants.spaceLg,
        AppConstants.spaceLg,
        0,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: c.borderPrimary, width: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              GoogleMap(
                liteModeEnabled: true,
                initialCameraPosition: CameraPosition(target: position, zoom: 16),
                markers: {
                  Marker(
                    markerId: MarkerId(placeId),
                    position: position,
                  ),
                },
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
              ),
              // Lite-mode GoogleMap swallows taps, so layer a transparent
              // Material InkWell over the whole map to forward the gesture.
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(onTap: onTap),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
