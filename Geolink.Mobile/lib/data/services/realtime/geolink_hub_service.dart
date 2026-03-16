import 'dart:async';

import 'package:signalr_netcore/signalr_client.dart';

import '../../../config/api_config.dart';
import '../../models/location.dart';
import '../local/secure_storage_service.dart';

class GeolinkHubService {
  GeolinkHubService({SecureStorageService? tokenStorage})
    : _tokenStorage = tokenStorage ?? SecureStorageService();

  final SecureStorageService _tokenStorage;

  HubConnection? _connection;

  final StreamController<Location> _friendLocationUpdates =
      StreamController<Location>.broadcast();

  Stream<Location> get friendLocationUpdates => _friendLocationUpdates.stream;

  bool get isConnected => _connection?.state == HubConnectionState.Connected;

  Future<void> connect() async {
    if (isConnected) {
      return;
    }

    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      throw StateError('Access token is missing. Cannot connect to hub.');
    }

    final connection = HubConnectionBuilder()
        .withUrl(
          '${ApiConfig.apiDomain}/hubs/geolink',
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token,
            transport: HttpTransportType.WebSockets,
          ),
        )
        .build();

    _registerHandlers(connection);

    await connection.start();
    _connection = connection;
  }

  Future<void> disconnect() async {
    final connection = _connection;
    if (connection == null) {
      return;
    }

    await connection.stop();
    _connection = null;
  }

  Future<void> sendLocation({
    required double latitude,
    required double longitude,
  }) async {
    final connection = _requireConnection();
    await connection.invoke(
      'UpdateLocation',
      args: <Object>[
        <String, dynamic>{'latitude': latitude, 'longitude': longitude},
      ],
    );
  }

  Future<void> dispose() async {
    await disconnect();
    await _friendLocationUpdates.close();
  }

  HubConnection _requireConnection() {
    final connection = _connection;
    if (connection == null ||
        connection.state != HubConnectionState.Connected) {
      throw StateError('Hub is not connected.');
    }

    return connection;
  }

  void _registerHandlers(HubConnection connection) {
    connection.on('FriendLocationUpdated', (arguments) {
      if (arguments == null || arguments.isEmpty) {
        return;
      }

      final location = _parseFriendLocation(arguments.first);
      if (location != null) {
        _friendLocationUpdates.add(location);
      }
    });
  }

  Location? _parseFriendLocation(Object? raw) {
    final map = _toStringKeyMap(raw);

    final userId = _readString(map, ['userId', 'UserId']);
    final latitude = _readDouble(map, ['latitude', 'Latitude']);
    final longitude = _readDouble(map, ['longitude', 'Longitude']);

    if (userId == null || latitude == null || longitude == null) {
      return null;
    }

    final updatedAtRaw =
        map['updatedAtUtc'] ??
        map['UpdatedAtUtc'] ??
        map['updatedAt'] ??
        map['UpdatedAt'];
    DateTime updatedAt = DateTime.now();
    if (updatedAtRaw is String) {
      updatedAt = DateTime.tryParse(updatedAtRaw) ?? updatedAt;
    }

    return Location(
      userId: userId,
      latitude: latitude,
      longitude: longitude,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> _toStringKeyMap(Object? raw) {
    if (raw is! Map) {
      return const <String, dynamic>{};
    }

    return raw.map((key, value) => MapEntry(key.toString(), value));
  }

  String? _readString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) {
        continue;
      }

      final text = value.toString();
      if (text.isNotEmpty) {
        return text;
      }
    }

    return null;
  }

  double? _readDouble(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) {
        continue;
      }

      if (value is num) {
        return value.toDouble();
      }

      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }

    return null;
  }
}
