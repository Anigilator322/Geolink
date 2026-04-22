import 'package:flutter/material.dart';
import '../../../data/services/api/auth_api_service.dart';
import '../../../data/services/local/secure_storage_service.dart';

class EmailViewModel extends ChangeNotifier {
  final AuthApiService _authApiService;
  final SecureStorageService _tokenStorage;

  bool isLoading = false;
  String? errorMessage;

  final emailController = TextEditingController();

  EmailViewModel({
    AuthApiService? authApiService,
    SecureStorageService? tokenStorage,
  }) : _authApiService = authApiService ?? AuthApiService(),
       _tokenStorage = tokenStorage ?? SecureStorageService();

  Future<bool> signIn() async {
    final email = emailController.text.trim();
    errorMessage = null;

    if (email.isEmpty) {
      errorMessage = 'Введите e-mail';
      notifyListeners();
      return false;
    }

    isLoading = true;
    notifyListeners();

    try {
      final response = await _authApiService.signInWithEmail(email);

      if (response.accessToken.isEmpty || response.refreshToken.isEmpty) {
        throw Exception('Сервер не вернул токены авторизации');
      }

      await _tokenStorage.save(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        email: response.email.isEmpty ? email : response.email,
      );

      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}
