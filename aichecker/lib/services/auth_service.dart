import 'package:dio/dio.dart';

class AuthService {
  static const String baseUrl = 'http://localhost:8080';
  late final Dio _dio;

  AuthService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
      headers: {'Content-Type': 'application/json'},
    ));
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/sign_in', data: {
        'email': email,
        'password': password,
      });

      final data = response.data;
      return {
        'success': !(data['error'] ?? false),
        'message': data['message'] ?? 'Успешная авторизация',
        'error': data['error'] ?? false,
      };
    } on DioException catch (e) {
      if (e.response != null) {
        try {
          final data = e.response!.data;
          return {
            'success': false,
            'message': data['message'] ?? 'Ошибка авторизации',
            'error': true,
          };
        } catch (_) {
          return {
            'success': false,
            'message': 'Ошибка авторизации: ${e.response!.statusCode}',
            'error': true,
          };
        }
      }
      return {
        'success': false,
        'message': 'Ошибка соединения: ${e.message}',
        'error': true,
      };
    }
  }

  Future<Map<String, dynamic>> register(
      String username, String email, String password) async {
    try {
      final response = await _dio.post('/sign_up', data: {
        'username': username,
        'email': email,
        'password': password,
      });

      final data = response.data;
      return {
        'success': !(data['error'] ?? false),
        'message': data['message'] ?? 'Успешная регистрация',
        'error': data['error'] ?? false,
      };
    } on DioException catch (e) {
      if (e.response != null) {
        try {
          final data = e.response!.data;
          return {
            'success': false,
            'message': data['message'] ?? 'Ошибка регистрации',
            'error': true,
          };
        } catch (_) {
          return {
            'success': false,
            'message': 'Ошибка регистрации: ${e.response!.statusCode}',
            'error': true,
          };
        }
      }
      return {
        'success': false,
        'message': 'Ошибка соединения: ${e.message}',
        'error': true,
      };
    }
  }
}
