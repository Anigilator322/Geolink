// MOCK — замените на реальную интеграцию с пакетом signalr_netcore.
//
// Реальный поток данных:
//   1. Клиент подключается к хабу с JWT-токеном в заголовке.
//   2. Хаб регистрирует userId → connectionId на сервере.
//   3. Клиент периодически вызывает UpdateLocation(lat, lng) — сервер сохраняет
//      позицию и сам рассылает событие FriendLocationUpdated всем онлайн-друзьям.
//   4. Клиент пассивно получает FriendLocationUpdated — он никогда не запрашивает
//      позиции конкретных друзей явно. Сервер знает друзей через БД + JWT.
//
// В реальной реализации:
//   final _connection = HubConnectionBuilder()
//       .withUrl('$baseUrl/geolinkHub',
//           options: HttpConnectionOptions(
//             accessTokenFactory: () async => await tokenService.getToken(),
//           ))
//       .build();
//
//   _connection.on('FriendLocationUpdated', (args) { ... });
//   await _connection.invoke('UpdateLocation', args: [lat, lng, accuracy]);

import 'dart:async';
import 'dart:math';

import '../../../domain/models/location.dart';
import '../local/secure_storage_service.dart';

class GeolinkHubService {
  final SecureStorageService _storage;

  // В продакшне: HubConnection из signalr_netcore
  final _controller = StreamController<Location>.broadcast();
  Timer? _timer;
  final _random = Random();

  // MOCK: те же userId, которые возвращает FriendApiService
  static const _mockFriendIds = ['friend_1', 'friend_2', 'friend_3'];
  static const _baseLat = 55.7558;
  static const _baseLng = 37.6173;

  // MOCK: URL хаба. В продакшне берётся из конфига.
  static const _hubUrl = 'https://api.geolink.app/geolinkHub';

  GeolinkHubService(this._storage);

  /// Поток событий FriendLocationUpdated от сервера.
  Stream<Location> get friendLocationStream => _controller.stream;

  /// Подключается к хабу, передавая JWT как accessTokenFactory.
  /// Сервер извлекает userId из токена и регистрирует connectionId.
  Future<void> connect() async {
    final token = await _storage.getAccessToken();

    // MOCK: логируем подключение с токеном
    // ignore: avoid_print
    print('[GeolinkHubService] Connecting to $_hubUrl');
    // ignore: avoid_print
    print('[GeolinkHubService] accessToken: ${_truncate(token)}');

    // В продакшне:
    //   _connection = HubConnectionBuilder()
    //       .withUrl(_hubUrl,
    //           options: HttpConnectionOptions(
    //             accessTokenFactory: () async => token,
    //           ))
    //       .build();
    //   _connection.on('FriendLocationUpdated', _onFriendLocationUpdated);
    //   await _connection.start();

    await Future.delayed(const Duration(milliseconds: 500));
    _startMockEmitting();
  }

  /// MOCK: эмулирует входящие события FriendLocationUpdated от сервера.
  /// В продакшне этот метод не нужен — данные приходят через _connection.on(...).
  void _startMockEmitting() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_controller.isClosed) return;
      // Сервер выбирает, кому отправить, на основе таблицы дружб.
      // В моке выбираем случайного друга из захардкоженного списка.
      final id = _mockFriendIds[_random.nextInt(_mockFriendIds.length)];
      _controller.add(Location(
        userId: id,
        latitude: _baseLat + (_random.nextDouble() - 0.5) * 0.05,
        longitude: _baseLng + (_random.nextDouble() - 0.5) * 0.05,
        updatedAt: DateTime.now(),
      ));
    });
  }

  /// Отправляет нашу текущую GPS-позицию на сервер.
  Future<void> sendLocation(double lat, double lng) async {
    // В продакшне:
    //   await _connection.invoke('UpdateLocation', args: [
    //     {'latitude': lat, 'longitude': lng, 'accuracy': null}
    //   ]);
    // ignore: avoid_print
    print('[GeolinkHubService] UpdateLocation → lat=$lat lng=$lng');
    await Future.delayed(const Duration(milliseconds: 50));
  }

  Future<void> disconnect() async {
    _timer?.cancel();
    if (!_controller.isClosed) await _controller.close();
    // В продакшне: await _connection.stop();
  }

  static String _truncate(String? s) =>
      s == null ? 'null' : '${s.substring(0, s.length.clamp(0, 20))}...';
}
