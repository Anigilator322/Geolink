import 'package:dio/dio.dart';
import 'api_client.dart';

class ProfileData {
  final String username;
  final String bio;

  const ProfileData({
    required this.username,
    required this.bio,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      username: (json['name'] ?? json['Name'] ?? '').toString(),
      bio: (json['bio'] ?? json['Bio'] ?? '').toString(),
    );
  }
}

class ApiProfileService {
  ApiProfileService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<ProfileData> getProfile() async {
    try {
      final response = await _apiClient.dio.get(
        '/me',
        options: Options(
          extra: {
            'requiresAuth': true,
            'allowAutoRefresh': true,
          },
        ),
      );

      final data = _toMap(response.data);
      return ProfileData.fromJson(data);
    } on DioException catch (e) {
      throw Exception(
        ApiClient.extractError(
          e,
          fallback: 'Не удалось загрузить профиль',
        ),
      );
    }
  }

  Future<ProfileData> updateProfile({
    required String username,
    required String bio,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '/me',
        data: {
          'username': username,
          'bio': bio,
        },
        options: Options(
          extra: {
            'requiresAuth': true,
            'allowAutoRefresh': true,
          },
        ),
      );

      final data = _toMap(response.data);
      return ProfileData.fromJson(data);
    } on DioException catch (e) {
      throw Exception(
        ApiClient.extractError(
          e,
          fallback: 'Не удалось сохранить профиль',
        ),
      );
    }
  }

  Map<String, dynamic> _toMap(Object? data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }

    return <String, dynamic>{};
  }
}