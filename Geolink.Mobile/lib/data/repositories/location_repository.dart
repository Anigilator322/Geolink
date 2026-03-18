import '../models/location.dart';
import '../services/api/location_api_service.dart';
import '../services/local/location_service.dart';
import '../services/realtime/geolink_hub_service.dart';

class LocationRepository {
  LocationRepository({
    GeolinkHubService? hubService,
    LocationService? locationService,
    LocationApiService? locationApiService,
  }) : _hubService = hubService ?? GeolinkHubService(),
       _locationService = locationService ?? LocationService(),
       _locationApiService = locationApiService ?? LocationApiService();

  final GeolinkHubService _hubService;
  final LocationService _locationService;
  final LocationApiService _locationApiService;

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

  Future<List<Location>> getLatestFriendLocations() {
    return _locationApiService.getLatestFriendLocations();
  }

  Future<void> dispose() async {
    await _hubService.dispose();
  }
}
