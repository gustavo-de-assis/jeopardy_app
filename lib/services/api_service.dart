import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_models.dart';

final apiServiceProvider = Provider((ref) => ApiService());

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:3000',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));

  void setBaseUrl(String url) {
    _dio.options.baseUrl = url;
    print('ApiService: Base URL updated to ${_dio.options.baseUrl}');
  }

  Future<List<Category>> getCategories() async {
    try {
      print('GET /categories');
      final response = await _dio.get('/categories');
      print('Categories response: ${response.data}');
      return (response.data as List).map((c) => Category.fromJson(c)).toList();
    } catch (e) {
      print('Error in getCategories: $e');
      rethrow;
    }
  }

  Future<List<Question>> getQuestionsByCategories(List<String> categoryIds) async {
    try {
      print('POST /questions/by-categories with $categoryIds');
      final response = await _dio.post('/questions/by-categories', data: {
        'categoryIds': categoryIds,
      });
      print('Questions response: ${response.data}');
      return (response.data as List).map((q) => Question.fromJson(q)).toList();
    } catch (e) {
      print('Error in getQuestionsByCategories: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> seedCategories() async {
    try {
      final response = await _dio.post('/categories/seed');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> seedQuestions() async {
    try {
      final response = await _dio.post('/questions/seed');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createSession(String hostId) async {
    try {
      final response = await _dio.post('/game-sessions', data: {'hostId': hostId});
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateSessionCategories(String sessionId, List<String> categoryIds) async {
    try {
      final response = await _dio.patch('/game-sessions/$sessionId/categories', data: {'categoryIds': categoryIds});
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> registerUser(String nickname, String email, String password) async {
    try {
      final response = await _dio.post('/users/register', data: {
        'nickname': nickname,
        'email': email,
        'password': password,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSessionByRoomCode(String roomCode) async {
    try {
      final response = await _dio.get('/game-sessions/room/$roomCode');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
