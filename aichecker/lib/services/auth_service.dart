import 'package:dio/dio.dart';
import 'token_storage.dart';

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

    // Добавляем interceptor для автоматической отправки токенов
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Добавляем токен к каждому запросу (кроме sign_in и sign_up)
          if (!options.path.contains('/sign_in') &&
              !options.path.contains('/sign_up')) {
            final authHeader = await TokenStorage.getAuthorizationHeader();
            if (authHeader != null) {
              options.headers['Authorization'] = authHeader;
            }
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Если получили 401, значит токен истек - перенаправляем на логин
          if (error.response?.statusCode == 401) {
            await TokenStorage.clearTokens();
            // Можно здесь добавить навигацию на страницу логина
          }
          return handler.next(error);
        },
      ),
    );
  }

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
    } on DioException catch (e) {
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
    if (e.response != null) {
      try {
        final data = e.response!.data;
        return {
          'success': false,
          'message': data['message'] ??
              data['detail'] ??
              '$defaultMessage: ${e.response!.statusCode}',
          'error': true,
        };
      } catch (_) {
        return {
          'success': false,
          'message': '$defaultMessage: ${e.response!.statusCode}',
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
