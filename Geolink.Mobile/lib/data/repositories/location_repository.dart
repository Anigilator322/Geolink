import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/realtime/geolink_hub_service.dart';
import '../services/local/location_service.dart';
import '../services/local/secure_storage_service.dart';
import '../../domain/models/location.dart';

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  final repo = LocationRepository(
    GeolinkHubService(ref.read(secureStorageServiceProvider)),
    LocationService(),
  );
  ref.onDispose(repo.dispose);
  return repo;
});

/// Единая точка доступа к геолокационным данным.
/// Объединяет SignalR (позиции друзей) и GPS устройства (собственная позиция).
class LocationRepository {
  final GeolinkHubService _hubService;
  final LocationService _locationService;

  // Кэш последних известных позиций друзей
  final Map<String, Location> _cache = {};

  LocationRepository(this._hubService, this._locationService);

  Future<void> connect() => _hubService.connect();

  /// Stream позиций друзей из SignalR. Каждое событие — обновление одного друга.
  Stream<Location> getFriendLocationUpdates() {
    return _hubService.friendLocationStream.map((loc) {
      _cache[loc.userId] = loc;
      return loc;
    });
  }

  /// Непрерывный поток собственной GPS-позиции.
  Stream<Location> getCurrentUserLocation() {
    return _locationService.getPositionStream();
  }

  /// Разовый запрос позиции при старте приложения.
  Future<Location> getCurrentUserLocationOnce() {
    return _locationService.getCurrentPosition();
  }

  /// Отправляет текущую позицию на сервер через SignalR.
  Future<void> broadcastMyLocation(double lat, double lng) {
    return _hubService.sendLocation(lat, lng);
  }

  Future<void> dispose() => _hubService.disconnect();
}
