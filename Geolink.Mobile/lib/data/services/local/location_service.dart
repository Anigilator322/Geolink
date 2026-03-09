// MOCK — замените на реальную интеграцию с пакетом geolocator
import 'dart:async';
import 'dart:math';

import '../../../domain/models/location.dart';

class LocationService {
  final _random = Random();

  static const _myUserId = 'me';
  static const _baseLat = 55.7558;
  static const _baseLng = 37.6173;

  /// Непрерывный поток GPS-позиций устройства.
  Stream<Location> getPositionStream() async* {
    while (true) {
      // MOCK: обновление каждые 5 секунд с небольшим смещением
      await Future.delayed(const Duration(seconds: 5));
      yield Location(
        userId: _myUserId,
        latitude: _baseLat + (_random.nextDouble() - 0.5) * 0.01,
        longitude: _baseLng + (_random.nextDouble() - 0.5) * 0.01,
        updatedAt: DateTime.now(),
      );
    }
  }

  /// Разовый запрос текущей позиции (используется при инициализации).
  Future<Location> getCurrentPosition() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return Location(
      userId: _myUserId,
      latitude: _baseLat,
      longitude: _baseLng,
      updatedAt: DateTime.now(),
    );
  }
}
