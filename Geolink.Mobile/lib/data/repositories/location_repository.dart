import '../models/location.dart';
import '../services/local/location_service.dart';
import '../services/realtime/geolink_hub_service.dart';

class LocationRepository {
  LocationRepository({
    GeolinkHubService? hubService,
    LocationService? locationService,
  }) : _hubService = hubService ?? GeolinkHubService(),
       _locationService = locationService ?? LocationService();

  final GeolinkHubService _hubService;
  final LocationService _locationService;

  Stream<Location> get friendLocationUpdates =>
      _hubService.friendLocationUpdates;

  Future<void> connectRealtime() => _hubService.connect();

  Future<void> disconnectRealtime() => _hubService.disconnect();

  Future<Location> getCurrentUserLocationOnce() {
    return _locationService.getCurrentLocation();
  }

  Stream<Location> watchCurrentUserLocation({int distanceFilterMeters = 10}) {
    return _locationService.watchLocation(
      distanceFilterMeters: distanceFilterMeters,
    );
  }

  Future<void> sendLocation({
    required double latitude,
    required double longitude,
  }) {
    return _hubService.sendLocation(latitude: latitude, longitude: longitude);
  }

  Future<void> sendLocationModel(Location location) {
    return sendLocation(
      latitude: location.latitude,
      longitude: location.longitude,
    );
  }

  Future<void> dispose() async {
    await _hubService.dispose();
  }
}
