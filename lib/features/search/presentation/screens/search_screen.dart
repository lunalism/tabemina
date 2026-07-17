import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_locale_provider.dart';
import '../../../../core/utils/keyboard.dart';
import '../providers/search_providers.dart';
import '../widgets/gps_button.dart';
import '../widgets/search_area_button.dart';
import '../widgets/search_bar_overlay.dart';
import '../widgets/search_bottom_sheet.dart';

/// Search tab — full-bleed Google Map with a floating search bar at the top,
/// a draggable bottom sheet of restaurants, and a GPS recenter button that
/// tracks the sheet so it always sits just above it.
///
/// When the user pans the map far enough (> [_searchAreaThresholdMeters])
/// from the last search center, a "Search this area" pill appears between
/// the map and the sheet. Tapping it sets a search-center override in the
/// provider and refetches; the GPS button + text search both clear the
/// override and dismiss the pill.
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

  static const double _searchAreaThresholdMeters = 500;

  LatLng _currentCameraCenter = AppConstants.tokyoCenter;
  // Seeded to the initial map center, never null — that way the very first
  // onCameraIdle after a user pan can compute a real distance instead of
  // waiting for a separate baseline source.
  LatLng _lastSearchCenter = AppConstants.tokyoCenter;
  bool _showSearchAreaButton = false;

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  void _onCameraMove(CameraPosition pos) {
    _currentCameraCenter = pos.target;
  }


  void _onCameraIdle() {
    // Text search owns its own bias — don't compete with the "this area"
    // affordance.
    if (ref.read(searchQueryProvider).isNotEmpty) return;

    final distance = Geolocator.distanceBetween(
      _lastSearchCenter.latitude,
      _lastSearchCenter.longitude,
      _currentCameraCenter.latitude,
      _currentCameraCenter.longitude,
    );
    final shouldShow = distance > _searchAreaThresholdMeters;
    if (shouldShow != _showSearchAreaButton) {
      setState(() => _showSearchAreaButton = shouldShow);
    }
  }

  void _searchThisArea() {
    final target = _currentCameraCenter;
    ref
        .read(searchCenterOverrideProvider.notifier)
        .setCenter(target);
    setState(() {
      _lastSearchCenter = target;
      _showSearchAreaButton = false;
    });
  }

  void _onGpsCentered(LatLng position) {
    // GPS button reset: drop any override so the provider falls back to the
    // user's GPS position and the baseline matches the new map center.
    ref.read(searchCenterOverrideProvider.notifier).clear();
    setState(() {
      _lastSearchCenter = position;
      _showSearchAreaButton = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Typing in the search bar hides the pill — text search supersedes
    // the nearby "this area" affordance.
    ref.listen(searchQueryProvider, (prev, next) {
      if (next.isNotEmpty && _showSearchAreaButton) {
        setState(() => _showSearchAreaButton = false);
      }
    });

    final markers = ref.watch(searchResultsProvider).maybeWhen(
          data: (items) => {
            for (final r in items)
              Marker(
                markerId: MarkerId(r.id),
                position: LatLng(r.latitude, r.longitude),
                infoWindow: InfoWindow(title: r.name),
              ),
          },
          orElse: () => <Marker>{},
        );

    final lang = ref.watch(appLocaleProvider).languageCode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      // Full-bleed map + fraction-sized sheet must not resize with the
      // keyboard: a resizing body animates the sheet's availablePixels, so a
      // mid-drag keyboard dismissal would move snap targets under the finger.
      resizeToAvoidBottomInset: false,
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
                markers: markers,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                // Map interaction while typing means "done with the keyboard".
                onTap: (_) => dismissKeyboard(),
                // Fires once per gesture, unlike onCameraMove — the pill
                // logic in _onCameraMove/_onCameraIdle stays untouched.
                onCameraMoveStarted: dismissKeyboard,
                onCameraMove: _onCameraMove,
                onCameraIdle: _onCameraIdle,
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
              // "Search this area" pill — pinned above the sheet, follows it
              // up/down as the user drags.
              AnimatedBuilder(
                animation: _sheetController,
                builder: (context, child) {
                  final size = _sheetController.isAttached
                      ? _sheetController.size
                      : SearchBottomSheet.collapsedSize;
                  return Positioned(
                    left: 0,
                    right: 0,
                    bottom: bodyHeight * size + AppConstants.spaceLg,
                    child: Center(child: child),
                  );
                },
                child: SearchAreaButton(
                  visible: _showSearchAreaButton,
                  label: searchThisAreaLabel(lang),
                  onTap: _searchThisArea,
                ),
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
                child: GpsButton(
                  mapController: _mapController,
                  onCentered: _onGpsCentered,
                ),
              ),
              SearchBottomSheet(controller: _sheetController),
            ],
          );
        },
      ),
    );
  }
}
