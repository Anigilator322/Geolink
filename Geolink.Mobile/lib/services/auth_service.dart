import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auth_response.dart';

class ApiClient {
  final String baseUrl;
  final http.Client httpClient;

  ApiClient({
    required this.baseUrl,
    http.Client? httpClient,
  }) : httpClient = httpClient ?? http.Client();

  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final defaultHeaders = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    return await httpClient.post(
      uri,
      headers: {...defaultHeaders, ...?headers},
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> postWithAuth(
    String endpoint, {
    Map<String, dynamic>? body,
    required String accessToken,
  }) async {
    return post(
      endpoint,
      body: body,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
  }
}

class AuthService {
  final ApiClient? apiClient;

  AuthService({this.apiClient});

  /// Шаг 1: Отправить код OTP на почту
  /// Режим тестирования: использует статические данные
  Future<bool> sendCode(String email) async {
    try {
      // Если клиент API предоставлен, использовать реальный API
      if (apiClient != null) {
        final response = await apiClient!.post(
          '/api/auth/send-code',
          body: {'email': email},
        );
        return response.statusCode == 200;
      }

      // Реализация для тестирования
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Шаг 2: Проверить код OTP и получить токены аутентификации
  /// Режим тестирования: принимает любой 6-значный код
  Future<AuthResponse> verifyCode(String email, String code) async {
    try {
      // Если клиент API предоставлен, использовать реальный API
      if (apiClient != null) {
        final response = await apiClient!.post(
          '/api/auth/verify-code',
          body: {'email': email, 'code': code},
        );

        if (response.statusCode != 200) {
          throw Exception('Failed to verify code');
        }

        return AuthResponse.fromJson(jsonDecode(response.body));
      }

      // Реализация для тестирования
      if (code.isEmpty || code.length != 6) {
        throw Exception('Invalid code format');
      }

      await Future.delayed(const Duration(seconds: 1));

      // Вернуть ответ авторизации для тестирования
      return AuthResponse(
        userId: 'mock-user-${email.hashCode}',
        email: email,
        username: email.split('@')[0],
        accessToken: 'mock-access-token-${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'mock-refresh-token-${DateTime.now().millisecondsSinceEpoch}',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Обновить токен доступа
  /// Режим тестирования: возвращает новые токены
  Future<AuthResponse> refreshToken(String refreshToken) async {
    try {
      // Если клиент API предоставлен, использовать реальный API
      if (apiClient != null) {
        final response = await apiClient!.post(
          '/api/auth/refresh',
          body: {'refreshToken': refreshToken},
        );

        if (response.statusCode != 200) {
          throw Exception('Failed to refresh token');
        }

        return AuthResponse.fromJson(jsonDecode(response.body));
      }

      // Реализация для тестирования
      await Future.delayed(const Duration(seconds: 1));

      return AuthResponse(
        userId: 'mock-user-refresh',
        email: 'mock@example.com',
        username: 'mockuser',
        accessToken: 'mock-access-token-refreshed-${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'mock-refresh-token-refreshed-${DateTime.now().millisecondsSinceEpoch}',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
    } catch (e) {
      rethrow;
    }
  }
}
