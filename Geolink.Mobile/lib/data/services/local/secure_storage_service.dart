// MOCK — замените на flutter_secure_storage.
//
// В продакшне:
//   final _storage = FlutterSecureStorage();
//   Future<String?> getAccessToken() => _storage.read(key: 'access_token');
//   Future<void> saveTokens({required String access, required String refresh}) async {
//     await _storage.write(key: 'access_token', value: access);
//     await _storage.write(key: 'refresh_token', value: refresh);
//   }

import 'package:flutter_riverpod/flutter_riverpod.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

class SecureStorageService {
  // MOCK: захардкоженный JWT. В продакшне токен сохраняется после логина
  // и читается из зашифрованного хранилища устройства.
  //
  // Декодированный payload мока:
  //   { "sub": "user-uuid-1234", "name": "Иван Петров", "exp": ... }
  static const _mockToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
      '.eyJzdWIiOiJ1c2VyLXV1aWQtMTIzNCIsIm5hbWUiOiLQmNCy0LDQvSDQn9C10YLRgNC-0LIiLCJleHAiOjk5OTk5OTk5OTl9'
      '.MOCK_SIGNATURE';

  Future<String?> getAccessToken() async {
    // MOCK: всегда возвращает токен. В продакшне — null если пользователь не залогинен.
    return _mockToken;
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    // MOCK: ничего не сохраняем. В продакшне — flutter_secure_storage.write(...)
  }

  Future<void> clearTokens() async {
    // MOCK: ничего не удаляем. В продакшне — flutter_secure_storage.deleteAll()
  }
}
