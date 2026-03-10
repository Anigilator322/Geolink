import 'package:flutter/material.dart';
import '../models/auth_response.dart';
import '../services/auth_service.dart';
import '../services/secure_storage_service.dart';

enum AuthState { initial, loading, authenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService authService;
  final SecureStorageService storageService;

  AuthState state = AuthState.initial;
  AuthResponse? authResponse;
  String? errorMessage;
  String? email;

  // Шаг проверки OTP
  bool isOtpSent = false;

  AuthProvider({
    required this.authService,
    required this.storageService,
  });

  /// Отправить код OTP на почту
  Future<void> sendCode(String emailAddress) async {
    try {
      state = AuthState.loading;
      errorMessage = null;
      notifyListeners();

      final success = await authService.sendCode(emailAddress);

      if (success) {
        isOtpSent = true;
        email = emailAddress;
        state = AuthState.initial;
        notifyListeners();
      } else {
        throw Exception('Failed to send code');
      }
    } catch (e) {
      state = AuthState.error;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Проверить код OTP
  Future<void> verifyCode(String code) async {
    try {
      state = AuthState.loading;
      errorMessage = null;
      notifyListeners();

      if (email == null) {
        throw Exception('Email not set');
      }

      final response = await authService.verifyCode(email!, code);

      // Сохранить токены
      await storageService.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        userId: response.userId,
        email: response.email,
        username: response.username,
      );

      authResponse = response;
      state = AuthState.authenticated;
      isOtpSent = false;
      notifyListeners();
    } catch (e) {
      state = AuthState.error;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Обновить токен доступа
  Future<void> refreshAccessToken() async {
    try {
      final refreshToken = await storageService.getRefreshToken();
      if (refreshToken == null) {
        throw Exception('No refresh token available');
      }

      final response = await authService.refreshToken(refreshToken);

      await storageService.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        userId: response.userId,
        email: response.email,
        username: response.username,
      );

      authResponse = response;
      notifyListeners();
    } catch (e) {
      state = AuthState.error;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Проверить вошел ли пользователь (из хранилища)
  Future<void> checkLoginStatus() async {
    try {
      final isLoggedIn = await storageService.isLoggedIn();
      if (isLoggedIn) {
        final userId = await storageService.getUserId();
        final email = await storageService.getEmail();
        final username = await storageService.getUsername();
        final accessToken = await storageService.getAccessToken();

        if (userId != null && email != null && accessToken != null) {
          authResponse = AuthResponse(
            userId: userId,
            email: email,
            username: username ?? '',
            accessToken: accessToken,
            refreshToken: '',
            expiresAt: DateTime.now().add(const Duration(hours: 1)),
          );
          state = AuthState.authenticated;
        }
      } else {
        state = AuthState.initial;
      }
      notifyListeners();
    } catch (e) {
      state = AuthState.error;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Выход
  Future<void> logout() async {
    try {
      await storageService.clearAll();
      authResponse = null;
      state = AuthState.initial;
      isOtpSent = false;
      errorMessage = null;
      email = null;
      notifyListeners();
    } catch (e) {
      state = AuthState.error;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  bool get isAuthenticated => state == AuthState.authenticated;
  bool get isLoading => state == AuthState.loading;
  bool get hasError => state == AuthState.error;
}
