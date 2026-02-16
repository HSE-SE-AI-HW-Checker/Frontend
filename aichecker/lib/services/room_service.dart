import 'package:dio/dio.dart';
import 'api_client.dart';

class RoomService {
  final _apiClient = ApiClient();
  Dio get _dio => _apiClient.dio;

  /// Отправить решение задачи
  Future<Map<String, dynamic>> submitSolution(String githubUrl) async {
    try {
      final response = await _dio.post('/submit', data: {
        'data': githubUrl,
        'data_type': 0,
      });

      final data = response.data;

      return {
        'success': true,
        'message': data['message'] ?? 'Решение отправлено на проверку',
        'data': data,
      };
    } on DioException catch (e) {
      return _handleError(e, 'Ошибка отправки решения');
    }
  }

  /// Обработка ошибок
  Map<String, dynamic> _handleError(DioException e, String defaultMessage) {
    return _apiClient.handleError(e, defaultMessage);
  }
}
