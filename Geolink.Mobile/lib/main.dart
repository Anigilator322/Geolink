import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/auth/send_code_screen.dart';
import 'screens/auth/verify_code_screen.dart';
import 'screens/home_screen.dart';
import 'providers/auth_provider.dart';
import 'services/auth_service.dart';
import 'services/secure_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализировать сервисы
  final storageService = SecureStorageService();
  final authService = AuthService(
    apiClient: null,
    // Раскомментируйте и установите baseUrl для использования реального API:
    // apiClient: ApiClient(baseUrl: 'http://localhost:5000'),
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<SecureStorageService>(
          create: (_) => storageService,
        ),
        Provider<AuthService>(
          create: (_) => authService,
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authService: authService,
            storageService: storageService,
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geolink',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const AuthWrapper(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _showVerifyCode = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.checkLoginStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Если аутентифицирован, показать главный экран
        if (authProvider.isAuthenticated) {
          return const HomeScreen();
        }

        // Если не аутентифицирован, показать процесс входа
        if (_showVerifyCode) {
          return VerifyCodeScreen(
            onVerified: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/home',
                (route) => false,
              );
            },
            onBackPressed: () {
              setState(() {
                _showVerifyCode = false;
              });
            },
          );
        }

        return SendCodeScreen(
          onCodeSent: () {
            setState(() {
              _showVerifyCode = true;
            });
          },
        );
      },
    );
  }
}
