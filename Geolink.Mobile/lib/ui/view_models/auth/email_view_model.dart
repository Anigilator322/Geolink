import 'dart:async';
import 'package:flutter/material.dart';

class EmailViewModel extends ChangeNotifier {
  bool isCodeSent = false;
  int timerSeconds = 57;

  final emailController = TextEditingController();
  final codeController = TextEditingController();

  Timer? _timer;

  EmailViewModel() {
    codeController.addListener(_onCodeChanged);
  }

  void sendCode() {
    isCodeSent = true;
    timerSeconds = 57;
    codeController.clear();
    _startTimer();
    notifyListeners();
  }

  void goBack() {
    isCodeSent = false;
    _timer?.cancel();
    notifyListeners();
  }

  void _onCodeChanged() {
    if (codeController.text.length == 4) {
      _verifyCode();
    }
  }

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

  void _verifyCode() {}

  @override
  void dispose() {
    _timer?.cancel();
    emailController.dispose();
    codeController.dispose();
    super.dispose();
  }
}