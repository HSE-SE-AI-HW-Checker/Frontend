import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import 'api_client.dart';
import '../models/room.dart';

class RoomService {
  final _apiClient = ApiClient();
  Dio get _dio => _apiClient.dio;

  // Моки для разработки
  static const bool _useMocks = false;

  /// Загрузить моки из JSON файла
  Future<List<Room>> _loadMockRooms(String assetPath) async {
    final jsonString = await rootBundle.loadString(assetPath);
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    final List<dynamic> roomsJson = jsonData['rooms'];
    return roomsJson.map((json) => Room.fromJson(json)).toList();
  }

  /// Получить недавние комнаты
  Future<List<Room>> getRecentRooms() async {
    if (_useMocks) {
      // Имитация задержки сети
      await Future.delayed(const Duration(milliseconds: 500));
      return await _loadMockRooms('assets/mocks/recent_rooms.json');
    }

    try {
      final response = await _dio.get('/rooms/recent');
      final List<dynamic> data = response.data['rooms'];
      return data.map((json) => Room.fromJson(json)).toList();
    } on DioException catch (e) {
      final error = _handleError(e, 'Ошибка загрузки недавних комнат');
      throw Exception(error['message']);
    }
  }

  /// Получить мои комнаты
  Future<List<Room>> getMyRooms() async {
    if (_useMocks) {
      // Имитация задержки сети
      await Future.delayed(const Duration(milliseconds: 500));
      return await _loadMockRooms('assets/mocks/my_rooms.json');
    }

    try {
      final response = await _dio.get('/rooms');
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => Room.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final error = _handleError(e, 'Ошибка загрузки моих комнат');
      throw Exception(error['message']);
    }
  }

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

