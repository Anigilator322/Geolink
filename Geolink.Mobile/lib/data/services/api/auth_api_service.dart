import 'package:dio/dio.dart';
import '../responses/auth_response.dart';
import 'api_client.dart';

class AuthApiService {
  AuthApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<void> sendCode(String email) async {
    try {
      await _apiClient.dio.post(
        '/auth/send-code',
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw Exception(
        ApiClient.extractError(
          e,
          fallback: 'Не удалось отправить код',
        ),
      );
    }
  }

  Future<AuthResponse> verifyCode(String email, String code) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/verify-code',
        data: {
          'email': email,
          'code': code,
        },
      );

      final json = response.data as Map<String, dynamic>;
      return AuthResponse.fromJson(json);
    } on DioException catch (e) {
      throw Exception(
        ApiClient.extractError(
          e,
          fallback: 'Неверный или истекший код',
        ),
      );
    }
  }
}
