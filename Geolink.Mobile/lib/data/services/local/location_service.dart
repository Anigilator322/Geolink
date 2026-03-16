import 'package:geolocator/geolocator.dart' as geo;

import '../../models/location.dart';

class LocationService {
  Future<Location> getCurrentLocation({
    String userId = 'me',
    geo.LocationAccuracy accuracy = geo.LocationAccuracy.high,
  }) async {
    await _ensureLocationReady();

    final position = await geo.Geolocator.getCurrentPosition(
      locationSettings: geo.LocationSettings(accuracy: accuracy),
    );

    return _toLocation(position, userId);
  }

  Stream<Location> watchLocation({
    String userId = 'me',
    geo.LocationAccuracy accuracy = geo.LocationAccuracy.high,
    int distanceFilterMeters = 10,
  }) async* {
    await _ensureLocationReady();

    yield* geo.Geolocator.getPositionStream(
      locationSettings: geo.LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilterMeters,
      ),
    ).map((position) => _toLocation(position, userId));
  }

  Future<void> _ensureLocationReady() async {
    final isServiceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      throw StateError('GPS is disabled. Please enable location services.');
    }

    var permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
    }

    if (permission == geo.LocationPermission.denied ||
        permission == geo.LocationPermission.deniedForever) {
      throw StateError('Location permission is denied.');
    }
  }

  Location _toLocation(geo.Position position, String userId) {
    return Location(
      userId: userId,
      latitude: position.latitude,
      longitude: position.longitude,
      updatedAt: DateTime.now(),
    );
  }
}
