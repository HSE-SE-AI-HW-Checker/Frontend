import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://localhost:8080';

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final uri = Uri.parse('$baseUrl/login').replace(queryParameters: {
        'email': email,
        'password': password,
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': !(data['error'] ?? false),
          'message': data['message'] ?? 'Успешная авторизация',
          'error': data['error'] ?? false,
        };
      } else {
        try {
          final data = jsonDecode(response.body);
          return {
            'success': false,
            'message': data['message'] ?? 'Ошибка авторизации',
            'error': true,
          };
        } catch (_) {
          return {
            'success': false,
            'message': 'Ошибка авторизации: ${response.statusCode}',
            'error': true,
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Ошибка соединения: $e',
        'error': true,
      };
    }
  }

  Future<Map<String, dynamic>> register(
      String username, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': !(data['error'] ?? false),
          'message': data['message'] ?? 'Успешная регистрация',
          'error': data['error'] ?? false,
        };
      } else {
        try {
          final data = jsonDecode(response.body);
          return {
            'success': false,
            'message': data['message'] ?? 'Ошибка регистрации',
            'error': true,
          };
        } catch (_) {
          return {
            'success': false,
            'message': 'Ошибка регистрации: ${response.statusCode}',
            'error': true,
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Ошибка соединения: $e',
        'error': true,
      };
    }
  }
}
