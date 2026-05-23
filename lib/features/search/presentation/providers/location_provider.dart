import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/location_service.dart';

/// Riverpod provider for the shared [LocationService] singleton.
final locationServiceProvider = Provider<LocationService>(
  (ref) => const LocationService(),
);
