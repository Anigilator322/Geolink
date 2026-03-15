import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/responses/auth_response.dart';

class AuthApiService {
  static const String _baseUrl = 'http://192.168.0.15:5169/api/auth';

  Future<void> sendCode(String email) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/send-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response.body, fallback: 'Не удалось отправить код'));
    }
  }

  Future<AuthResponse> verifyCode(String email, String code) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/verify-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'code': code,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response.body, fallback: 'Неверный или истекший код'));
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return AuthResponse.fromJson(json);
  }

  String _extractError(String body, {required String fallback}) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is String && decoded.isNotEmpty) return decoded;
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'] ?? decoded['message'] ?? decoded['title'];
        if (error is String && error.isNotEmpty) return error;
      }
    } catch (_) {}
    return fallback;
  }
}