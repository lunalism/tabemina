import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/app_constants.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tabemina 食べみな')),
      body: const GoogleMap(
        initialCameraPosition: CameraPosition(
          target: AppConstants.tokyoCenter,
          zoom: AppConstants.defaultMapZoom,
        ),
        myLocationButtonEnabled: true,
      ),
    );
  }
}
