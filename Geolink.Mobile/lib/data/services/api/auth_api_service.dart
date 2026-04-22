import 'package:dio/dio.dart';
import '../responses/auth_response.dart';
import 'api_client.dart';

class AuthApiService {
  AuthApiService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<AuthResponse> signInWithEmail(String email) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/send-code',
        data: {'email': email},
        options: Options(
          extra: {'requiresAuth': false, 'allowAutoRefresh': false},
        ),
      );

      final json = response.data as Map<String, dynamic>;
      return AuthResponse.fromJson(json);
    } on DioException catch (e) {
      throw Exception(
        ApiClient.extractError(e, fallback: 'Не удалось выполнить вход'),
      );
    }
  }

  Future<AuthResponse> refreshToken(String refreshToken) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/refresh-token',
        data: {'refreshToken': refreshToken},
        options: Options(
          extra: {'requiresAuth': false, 'allowAutoRefresh': false},
        ),
      );

      final json = response.data as Map<String, dynamic>;
      return AuthResponse.fromJson(json);
    } on DioException catch (e) {
      throw Exception(
        ApiClient.extractError(e, fallback: 'Failed to refresh auth token.'),
      );
    }
  }
}
