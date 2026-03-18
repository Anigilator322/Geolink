import 'package:dio/dio.dart';

import '../../models/location.dart';
import 'api_client.dart';

class LocationApiService {
  LocationApiService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Location>> getLatestFriendLocations() async {
    try {
      final response = await _apiClient.dio.get('/location/friends/map');
      final payload = _extractList(response.data);

      return payload
          .map(_toStringKeyMap)
          .map(_toLocation)
          .whereType<Location>()
          .toList();
    } on DioException catch (e) {
      throw Exception(
        ApiClient.extractError(
          e,
          fallback: 'Failed to load latest friend locations.',
        ),
      );
    }
  }

  List<Object?> _extractList(Object? payload) {
    if (payload is List) {
      return payload.cast<Object?>();
    }

    return const <Object?>[];
  }

  Map<String, dynamic> _toStringKeyMap(Object? payload) {
    if (payload is! Map) {
      return const <String, dynamic>{};
    }

    return payload.map((key, value) => MapEntry(key.toString(), value));
  }

  Location? _toLocation(Map<String, dynamic> json) {
    final userId = _readString(json, ['userId', 'UserId']);
    final latitude = _readDouble(json, ['latitude', 'Latitude']);
    final longitude = _readDouble(json, ['longitude', 'Longitude']);

    if (userId == null || latitude == null || longitude == null) {
      return null;
    }

    final updatedAtRaw =
        json['updatedAtUtc'] ??
        json['UpdatedAtUtc'] ??
        json['updatedAt'] ??
        json['UpdatedAt'];

    DateTime updatedAt = DateTime.now();
    if (updatedAtRaw is String && updatedAtRaw.isNotEmpty) {
      updatedAt = DateTime.tryParse(updatedAtRaw) ?? updatedAt;
    }

    return Location(
      userId: userId,
      latitude: latitude,
      longitude: longitude,
      updatedAt: updatedAt,
    );
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
