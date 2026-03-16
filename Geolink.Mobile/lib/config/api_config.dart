import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String apiDomain = dotenv.env['API_DOMAIN'] ?? 'http://localhost:5000';
  static String apiBaseUrl = '${dotenv.env['API_DOMAIN']}/api';
  static String authBaseUrl = '${dotenv.env['API_DOMAIN']}/api/auth';
}
