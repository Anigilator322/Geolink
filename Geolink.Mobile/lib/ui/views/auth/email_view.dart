import 'package:flutter/material.dart';
import '../../view_models/auth/email_view_model.dart';
import '../../core/theme/app_colors.dart';

class EmailView extends StatefulWidget {
  const EmailView({super.key});

  @override
  State<EmailView> createState() => _EmailViewState();
}

class _EmailViewState extends State<EmailView> {
  late final EmailViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = EmailViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => _buildScaffold(),
    );
  }

  Widget _buildScaffold() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: _viewModel.isCodeSent
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: _viewModel.goBack,
              )
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _viewModel.isCodeSent ? 'Код подтверждения' : 'Вход по e-mail',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 70),
            if (!_viewModel.isCodeSent) _buildEmailInput() else _buildCodeInput(),
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
          controller: _viewModel.emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'example@email.com',
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary, width: 2),
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
          controller: _viewModel.codeController,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 4,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 20,
          ),
          decoration: InputDecoration(
            counterText: '',
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 40),
        Center(
          child: _viewModel.timerSeconds > 0
              ? Text(
                  'Запросить код повторно можно через '
                  '0:${_viewModel.timerSeconds.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: AppColors.textGrey, fontSize: 14),
                )
              : GestureDetector(
                  onTap: _viewModel.sendCode,
                  child: const Text(
                    'Получить код повторно',
                    style: TextStyle(
                      color: AppColors.primary,
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
    if (_viewModel.isCodeSent) return const SizedBox(height: 40);

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 24),
          child: Text.rich(
            TextSpan(
              text: 'Продолжая регистрацию вы принимаете ',
              style: TextStyle(fontSize: 14, color: AppColors.textGrey),
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
            onPressed: _viewModel.sendCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text(
              'Получить код',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}