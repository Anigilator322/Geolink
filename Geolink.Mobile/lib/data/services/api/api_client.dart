import 'package:dio/dio.dart';
import '../../../config/api_config.dart';
import '../local/secure_storage_service.dart';

class ApiClient {
  ApiClient({
    SecureStorageService? tokenStorage,
    Dio? dio,
  })  : _tokenStorage = tokenStorage ?? SecureStorageService(),
        dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConfig.apiBaseUrl,
                headers: const {'Content-Type': 'application/json'},
              ),
            ) {
    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final SecureStorageService _tokenStorage;
  final Dio dio;

  static String extractError(
    DioException error, {
    required String fallback,
  }) {
    final data = error.response?.data;

    if (data is String && data.isNotEmpty) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      final message = data['error'] ?? data['message'] ?? data['title'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }

    return fallback;
  }
}
