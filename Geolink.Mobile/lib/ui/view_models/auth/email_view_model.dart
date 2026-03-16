import 'dart:async';
import 'package:flutter/material.dart';
import '../../../data/services/api/auth_api_service.dart';
import '../../../data/services/local/secure_storage_service.dart';

class EmailViewModel extends ChangeNotifier {
  final AuthApiService _authApiService;
  final SecureStorageService _tokenStorage;

  bool isCodeSent = false;
  bool isLoading = false;
  int timerSeconds = 57;
  String? errorMessage;

  final emailController = TextEditingController();
  final codeController = TextEditingController();

  Timer? _timer;

  EmailViewModel({
    AuthApiService? authApiService,
    SecureStorageService? tokenStorage,
  })  : _authApiService = authApiService ?? AuthApiService(),
        _tokenStorage = tokenStorage ?? SecureStorageService() {
    codeController.addListener(_onCodeChanged);
  }

  Future<bool> sendCode() async {
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
      await _authApiService.sendCode(email);

      isCodeSent = true;
      timerSeconds = 57;
      codeController.clear();
      _startTimer();

      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void goBack() {
    isCodeSent = false;
    errorMessage = null;
    codeController.clear();
    _timer?.cancel();
    notifyListeners();
  }

  void _onCodeChanged() {}//мб чтобы при вводе всех 6 символов сразу проверять код, но пока не реализовано

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (timerSeconds > 0) {
        timerSeconds--;
        notifyListeners();
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<bool> resendCode() async {
    return sendCode();
  }

  Future<bool> _verifyCode() async {
    final email = emailController.text.trim();
    final code = codeController.text.trim();

    errorMessage = null;
    isLoading = true;
    notifyListeners();

    try {
      final response = await _authApiService.verifyCode(email, code);

      await _tokenStorage.save(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        email: response.email,
      );

      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      codeController.clear();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyCodeManually() async {
    return _verifyCode();
  }

  @override
  void dispose() {
    _timer?.cancel();
    emailController.dispose();
    codeController.dispose();
    super.dispose();
  }
}