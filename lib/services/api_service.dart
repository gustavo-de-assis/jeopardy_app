import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_models.dart';

final apiServiceProvider = Provider((ref) => ApiService());

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:3000', // Update this if running on physical device (use your IP)
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));

  Future<List<Category>> getCategories() async {
    try {
      final response = await _dio.get('/categories');
      return (response.data as List).map((c) => Category.fromJson(c)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Question>> getQuestionsByCategories(List<String> categoryIds) async {
    try {
      final response = await _dio.post('/questions/by-categories', data: {
        'categoryIds': categoryIds,
      });
      return (response.data as List).map((q) => Question.fromJson(q)).toList();
    } catch (e) {
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
}
