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
  final StreamController<FriendRequestNotification> _friendRequestReceived =
      StreamController<FriendRequestNotification>.broadcast();
  final StreamController<EventInvitationNotification> _eventInvitations =
      StreamController<EventInvitationNotification>.broadcast();
  final StreamController<String> _friendOnlineUpdates =
      StreamController<String>.broadcast();
  final StreamController<String> _friendOfflineUpdates =
      StreamController<String>.broadcast();

  Stream<Location> get friendLocationUpdates => _friendLocationUpdates.stream;
  Stream<FriendRequestNotification> get friendRequestReceived =>
      _friendRequestReceived.stream;
  Stream<EventInvitationNotification> get eventInvitations =>
      _eventInvitations.stream;
  Stream<String> get friendOnlineUpdates => _friendOnlineUpdates.stream;
  Stream<String> get friendOfflineUpdates => _friendOfflineUpdates.stream;

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
            accessTokenFactory: () async {
              final latestToken = await _tokenStorage.getAccessToken();
              if (latestToken == null || latestToken.isEmpty) {
                throw StateError(
                  'Access token is missing. Cannot connect to hub.',
                );
              }

              return latestToken;
            },
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

  Future<void> sendFriendRequest({required String addresseeId}) async {
    final normalizedAddresseeId = addresseeId.trim();
    if (normalizedAddresseeId.isEmpty) {
      throw ArgumentError.value(
        addresseeId,
        'addresseeId',
        'addresseeId must not be empty.',
      );
    }

    final connection = _requireConnection();
    await connection.invoke(
      'SendFriendRequest',
      args: <Object>[normalizedAddresseeId],
    );
  }

  Future<void> notifyEventInvitation({
    required String eventId,
    required String inviteeId,
  }) async {
    final normalizedEventId = eventId.trim();
    final normalizedInviteeId = inviteeId.trim();

    if (normalizedEventId.isEmpty) {
      throw ArgumentError.value(
        eventId,
        'eventId',
        'eventId must not be empty.',
      );
    }

    if (normalizedInviteeId.isEmpty) {
      throw ArgumentError.value(
        inviteeId,
        'inviteeId',
        'inviteeId must not be empty.',
      );
    }

    final connection = _requireConnection();
    await connection.invoke(
      'NotifyEventInvitation',
      args: <Object>[normalizedEventId, normalizedInviteeId],
    );
  }

  Future<void> dispose() async {
    await disconnect();
    await _friendLocationUpdates.close();
    await _friendRequestReceived.close();
    await _eventInvitations.close();
    await _friendOnlineUpdates.close();
    await _friendOfflineUpdates.close();
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

    connection.on('FriendRequestReceived', (arguments) {
      if (arguments == null || arguments.isEmpty) {
        return;
      }

      final notification = _parseFriendRequestNotification(arguments.first);
      if (notification != null) {
        _friendRequestReceived.add(notification);
      }
    });

    connection.on('EventInvitation', (arguments) {
      if (arguments == null || arguments.isEmpty) {
        return;
      }

      final notification = _parseEventInvitation(arguments.first);
      if (notification != null) {
        _eventInvitations.add(notification);
      }
    });

    connection.on('FriendOnline', (arguments) {
      if (arguments == null || arguments.isEmpty) {
        return;
      }

      final userId = _parseUserId(arguments.first);
      if (userId != null) {
        _friendOnlineUpdates.add(userId);
      }
    });

    connection.on('FriendOffline', (arguments) {
      if (arguments == null || arguments.isEmpty) {
        return;
      }

      final userId = _parseUserId(arguments.first);
      if (userId != null) {
        _friendOfflineUpdates.add(userId);
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

  FriendRequestNotification? _parseFriendRequestNotification(Object? raw) {
    final map = _toStringKeyMap(raw);

    final userId = _readString(map, ['userId', 'UserId']);
    if (userId == null) {
      return null;
    }

    final username = _readString(map, ['username', 'Username']) ?? '';
    final avatarUrl = _readString(map, ['avatarUrl', 'AvatarUrl']);

    return FriendRequestNotification(
      userId: userId,
      username: username,
      avatarUrl: avatarUrl,
    );
  }

  EventInvitationNotification? _parseEventInvitation(Object? raw) {
    final map = _toStringKeyMap(raw);

    final eventId = _readString(map, ['eventId', 'EventId']);
    final inviterId = _readString(map, ['inviterId', 'InviterId']);

    if (eventId == null || inviterId == null) {
      return null;
    }

    final title = _readString(map, ['title', 'Title']) ?? '';

    return EventInvitationNotification(
      eventId: eventId,
      inviterId: inviterId,
      title: title,
    );
  }

  String? _parseUserId(Object? raw) {
    if (raw == null) {
      return null;
    }

    if (raw is String) {
      final userId = raw.trim();
      return userId.isNotEmpty ? userId : null;
    }

    if (raw is Map) {
      final map = _toStringKeyMap(raw);
      return _readString(map, ['userId', 'UserId', 'id', 'Id']);
    }

    final userId = raw.toString().trim();
    return userId.isNotEmpty ? userId : null;
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

class FriendRequestNotification {
  const FriendRequestNotification({
    required this.userId,
    required this.username,
    this.avatarUrl,
  });

  final String userId;
  final String username;
  final String? avatarUrl;
}

class EventInvitationNotification {
  const EventInvitationNotification({
    required this.eventId,
    required this.inviterId,
    required this.title,
  });

  final String eventId;
  final String inviterId;
  final String title;
}
