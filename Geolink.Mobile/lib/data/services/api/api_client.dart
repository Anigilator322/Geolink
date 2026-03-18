import 'package:dio/dio.dart';
import '../../../config/api_config.dart';
import '../local/secure_storage_service.dart';

class ApiClient {
  ApiClient({SecureStorageService? tokenStorage, Dio? dio})
    : _tokenStorage = tokenStorage ?? SecureStorageService(),
      dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConfig.apiBaseUrl,
              headers: const {'Content-Type': 'application/json'},
            ),
          ),
      _refreshDio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.apiBaseUrl,
          headers: const {'Content-Type': 'application/json'},
        ),
      ) {
    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final requiresAuth = options.extra['requiresAuth'] != false;
          if (!requiresAuth) {
            handler.next(options);
            return;
          }

          final token = await _tokenStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },
        onError: (error, handler) async {
          final statusCode = error.response?.statusCode;
          final requestOptions = error.requestOptions;
          final allowAutoRefresh =
              requestOptions.extra['allowAutoRefresh'] != false;
          final retriedWithFreshToken =
              requestOptions.extra['retriedWithFreshToken'] == true;

          if (statusCode != 401 || !allowAutoRefresh || retriedWithFreshToken) {
            handler.next(error);
            return;
          }

          final refreshed = await _refreshTokensWithSingleFlight();
          if (!refreshed) {
            handler.next(error);
            return;
          }

          final latestAccessToken = await _tokenStorage.getAccessToken();
          if (latestAccessToken == null || latestAccessToken.isEmpty) {
            handler.next(error);
            return;
          }

          final updatedHeaders = Map<String, dynamic>.from(
            requestOptions.headers,
          );
          updatedHeaders['Authorization'] = 'Bearer $latestAccessToken';

          final updatedExtra = Map<String, dynamic>.from(requestOptions.extra);
          updatedExtra['retriedWithFreshToken'] = true;

          final retriedRequest = requestOptions.copyWith(
            headers: updatedHeaders,
            extra: updatedExtra,
          );

          try {
            final response = await this.dio.fetch(retriedRequest);
            handler.resolve(response);
          } on DioException catch (retryError) {
            handler.next(retryError);
          }
        },
      ),
    );
  }

  final SecureStorageService _tokenStorage;
  final Dio dio;
  final Dio _refreshDio;
  static Future<bool>? _refreshInFlight;

  Future<bool> _refreshTokensWithSingleFlight() async {
    final inFlight = _refreshInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    final refreshFuture = _refreshAccessToken();
    _refreshInFlight = refreshFuture;

    try {
      return await refreshFuture;
    } finally {
      _refreshInFlight = null;
    }
  }

  Future<bool> _refreshAccessToken() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    try {
      final response = await _refreshDio.post(
        '/auth/refresh-token',
        data: {'refreshToken': refreshToken},
      );

      final payload = _toStringKeyMap(response.data);
      final accessToken = _readString(payload, ['accessToken', 'AccessToken']);
      final rotatedRefreshToken = _readString(payload, [
        'refreshToken',
        'RefreshToken',
      ]);

      if (accessToken == null || rotatedRefreshToken == null) {
        return false;
      }

      final email =
          _readString(payload, ['email', 'Email']) ??
          (await _tokenStorage.getEmail()) ??
          '';

      await _tokenStorage.save(
        accessToken: accessToken,
        refreshToken: rotatedRefreshToken,
        email: email,
      );

      return true;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 400 || statusCode == 401) {
        await _tokenStorage.clear();
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> _toStringKeyMap(Object? payload) {
    if (payload is! Map) {
      return const <String, dynamic>{};
    }

    return payload.map((key, value) => MapEntry(key.toString(), value));
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

  static String extractError(DioException error, {required String fallback}) {
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
