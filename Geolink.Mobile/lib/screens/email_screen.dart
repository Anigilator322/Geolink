import 'dart:async';
import 'package:flutter/material.dart';

class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  bool _isCodeSent = false;
  int _timerSeconds = 57;
  Timer? _timer;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _codeController.addListener(() {
      if (_codeController.text.length == 4) {
        _verifyCode();
      }
    });
  }

  void _startTimer() {
    setState(() {
      _isCodeSent = true;
      _timerSeconds = 57;
      _codeController.clear();
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timerSeconds > 0) {
            _timerSeconds--;
          } else {
            _timer?.cancel();
          }
        });
      }
    });
  }

  void _verifyCode() {
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: _isCodeSent
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  setState(() {
                    _isCodeSent = false;
                    _timer?.cancel();
                  });
                },
              )
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isCodeSent ? 'Код подтверждения' : 'Вход по e-mail',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 70),

            if (!_isCodeSent) _buildEmailInput() else _buildCodeInput(),

            const Spacer(),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Введите e-mail', style: TextStyle(fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'example@email.com',
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Мы отправили код\nна ваш e-mail', style: TextStyle(fontSize: 15)),
        const SizedBox(height: 32),
        TextField(
          controller: _codeController,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 4,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 20),
          decoration: InputDecoration(
            counterText: "",
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 40),
        Center(
          child: _timerSeconds > 0
              ? Text(
                  'Запросить код повторно можно через 0:${_timerSeconds.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                )
              : GestureDetector(
                  onTap: _startTimer,
                  child: const Text(
                    'Получить код повторно',
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildBottomSection() {
    return Column(
      children: [
        if (!_isCodeSent) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 24),
            child: Text.rich(
              TextSpan(
                text: 'Продолжая регистрацию вы принимаете ',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                children: [
                  TextSpan(
                    text: 'пользовательское соглашение',
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                  TextSpan(text: ' и '),
                  TextSpan(
                    text: 'политику конфиденциальности',
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _startTimer,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text(
                'Получить код',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
        const SizedBox(height: 40),
      ],
    );
  }
}
