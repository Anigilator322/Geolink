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
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: _viewModel.isCodeSent
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: _viewModel.isLoading ? null : _viewModel.goBack,
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
              if (_viewModel.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _viewModel.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
     bottomNavigationBar: SafeArea(
       top: false,
       child: Padding(
         padding: const EdgeInsets.symmetric(horizontal: 24),
         child: _buildBottomSection(),
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
          enabled: !_viewModel.isLoading,
          decoration: InputDecoration(
            hintText: 'example@email.com',
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Мы отправили код\nна ваш e-mail',
          style: TextStyle(fontSize: 15),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _viewModel.codeController,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          enabled: !_viewModel.isLoading,
          maxLength: 6,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 12,
          ),
          decoration: InputDecoration(
            counterText: '',
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (_viewModel.isLoading)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget _buildBottomSection() {
    if (_viewModel.isCodeSent) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _viewModel.isLoading
                  ? null
                  : () async {
                      final ok = await _viewModel.verifyCodeManually();
                      if (!mounted) return;
                      if (ok) {
                        Navigator.pushReplacementNamed(context, '/map');
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Подтвердить код',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: _viewModel.timerSeconds > 0
                ? Text(
                    'Запросить код повторно можно через '
                    '0:${_viewModel.timerSeconds.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 14,
                    ),
                  )
                : GestureDetector(
                    onTap: _viewModel.isLoading
                        ? null
                        : () async {
                            await _viewModel.resendCode();
                          },
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
          const SizedBox(height: 40),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
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
            onPressed: _viewModel.isLoading
                ? null
                : () async {
                    final ok = await _viewModel.sendCode();
                    if (!mounted) return;
                    if (!ok) return;
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: _viewModel.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
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