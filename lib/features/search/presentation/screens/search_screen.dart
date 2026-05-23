import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../widgets/gps_button.dart';
import '../widgets/search_bar_overlay.dart';
import '../widgets/search_bottom_sheet.dart';

/// Search tab — full-bleed Google Map with a floating search bar at the top,
/// a draggable bottom sheet of nearby restaurants, and a GPS recenter button
/// that tracks the sheet so it always sits just above it.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bodyHeight = constraints.maxHeight;
          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: AppConstants.tokyoCenter,
                  zoom: AppConstants.defaultMapZoom,
                ),
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                // Padding pushes Google's logo / attribution up so the sheet
                // doesn't cover them at the collapsed snap point.
                padding: EdgeInsets.only(
                  bottom: bodyHeight * SearchBottomSheet.collapsedSize,
                ),
                onMapCreated: (controller) {
                  if (!_mapController.isCompleted) {
                    _mapController.complete(controller);
                  }
                },
              ),
              const Align(
                alignment: Alignment.topCenter,
                child: SearchBarOverlay(),
              ),
              AnimatedBuilder(
                animation: _sheetController,
                builder: (context, child) {
                  final size = _sheetController.isAttached
                      ? _sheetController.size
                      : SearchBottomSheet.collapsedSize;
                  return Positioned(
                    right: AppConstants.spaceLg,
                    bottom: bodyHeight * size + AppConstants.spaceLg,
                    child: child!,
                  );
                },
                child: GpsButton(mapController: _mapController),
              ),
              SearchBottomSheet(controller: _sheetController),
            ],
          );
        },
      ),
    );
  }
}
