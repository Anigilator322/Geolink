// MOCK — замените на реальный Dio с DioOptions и Interceptor.
//
// В продакшне:
//   final _dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
//   _dio.interceptors.add(InterceptorsWrapper(
//     onRequest: (options, handler) async {
//       final token = await _storage.getAccessToken();
//       if (token != null) {
//         options.headers['Authorization'] = 'Bearer $token';
//       }
//       handler.next(options);
//     },
//     onError: (error, handler) async {
//       if (error.response?.statusCode == 401) {
//         // Refresh token logic...
//       }
//       handler.next(error);
//     },
//   ));

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/secure_storage_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.read(secureStorageServiceProvider));
});

/// HTTP-клиент с автоматической подстановкой JWT в заголовок Authorization.
/// Все REST-сервисы используют этот клиент — токен не передаётся в каждый
/// сервис вручную.
class ApiClient {
  final SecureStorageService _storage;

  // MOCK: захардкоженный базовый URL. В продакшне берётся из конфига/env.
  static const _baseUrl = 'https://api.geolink.app';

  ApiClient(this._storage);

  /// Возвращает заголовки с актуальным Bearer-токеном.
  /// В продакшне Dio-interceptor делает это прозрачно для каждого запроса.
  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// MOCK GET: имитирует HTTP GET с автоподстановкой JWT.
  /// В продакшне: return await _dio.get(path);
  Future<MockResponse> get(String path) async {
    final headers = await _authHeaders();

    // MOCK: логируем запрос, чтобы был виден Authorization header
    // ignore: avoid_print
    print('[ApiClient] GET $_baseUrl$path  headers: $headers');

    await Future.delayed(const Duration(milliseconds: 400));
    return MockResponse(path: '$_baseUrl$path', headers: headers);
  }
}

/// MOCK-заглушка ответа — в продакшне заменяется на Response из Dio.
class MockResponse {
  final String path;
  final Map<String, String> headers;
  const MockResponse({required this.path, required this.headers});
}
