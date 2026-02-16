import 'package:dio/dio.dart';
import 'api_client.dart';
import 'token_storage.dart';

class AuthService {
  final _apiClient = ApiClient();
  Dio get _dio => _apiClient.dio;

  /// Вход в систему
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/sign_in', data: {
        'email': email,
        'password': password,
      });

      final data = response.data;

      // Сохраняем токены
      if (data['access_token'] != null) {
        await TokenStorage.saveTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'] ?? '',
          tokenType: data['token_type'] ?? 'bearer',
        );
      }

      return {
        'success': !(data['error'] ?? false),
        'message': data['message'] ?? 'Успешная авторизация',
        'error': data['error'] ?? false,
      };
    } on DioException catch (e) {
      return _handleError(e, 'Ошибка авторизации');
    }
  }

  /// Регистрация нового пользователя
  Future<Map<String, dynamic>> register(
      String username, String email, String password) async {
    try {
      final response = await _dio.post('/sign_up', data: {
        'username': username,
        'email': email,
        'password': password,
      });

      final data = response.data;

      // Сохраняем токены
      if (data['access_token'] != null) {
        await TokenStorage.saveTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'] ?? '',
          tokenType: data['token_type'] ?? 'bearer',
        );
      }

      return {
        'success': !(data['error'] ?? false),
        'message': data['message'] ?? 'Успешная регистрация',
        'error': data['error'] ?? false,
      };
    } on DioException catch (e) {
      return _handleError(e, 'Ошибка регистрации');
    }
  }

  /// Выход из системы
  Future<Map<String, dynamic>> logout() async {
    try {
      // Отправляем запрос на сервер для отзыва токена
      final response = await _dio.post('/logout');

      // Удаляем токены локально
      await TokenStorage.clearTokens();

      final data = response.data;
      return {
        'success': data['success'] ?? true,
        'message': data['message'] ?? 'Выход выполнен',
      };
    } on DioException {
      // Даже если запрос упал, удаляем токены локально
      await TokenStorage.clearTokens();

      return {
        'success': true,
        'message': 'Выход выполнен',
      };
    }
  }

  /// Получить профиль текущего пользователя
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _dio.get('/me');
      final data = response.data;

      return {
        'success': true,
        'data': data,
      };
    } on DioException catch (e) {
      return _handleError(e, 'Ошибка получения профиля');
    }
  }

  /// Проверить, авторизован ли пользователь
  Future<bool> isAuthenticated() async {
    return await TokenStorage.hasTokens();
  }

  /// Обработка ошибок
  Map<String, dynamic> _handleError(DioException e, String defaultMessage) {
    return _apiClient.handleError(e, defaultMessage);
  }
}
