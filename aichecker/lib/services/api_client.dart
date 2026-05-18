import 'package:dio/dio.dart';
import 'token_storage.dart';
import '../config/app_config.dart';

class ApiClient {
  static const String baseUrl = AppConfig.baseUrl;
  late final Dio _dio;

  // Singleton pattern
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 120),
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
          // Если получили 401, значит токен истек
          if (error.response?.statusCode == 401) {
            await TokenStorage.clearTokens();
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Получить Dio клиент
  Dio get dio => _dio;

  /// Общий метод обработки ошибок
  Map<String, dynamic> handleError(DioException e, String defaultMessage) {
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
