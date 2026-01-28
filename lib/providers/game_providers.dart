import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_models.dart';
import '../services/api_service.dart';

class BoardData {
  final List<Category> categories;
  final Map<String, List<Question>> questionsByCategory;

  BoardData({required this.categories, required this.questionsByCategory});
}

final boardDataProvider = FutureProvider.family<BoardData, String>((ref, roomCode) async {
  final api = ref.read(apiServiceProvider);
  
  print('Fetching session data for room: $roomCode');
  final session = await api.getSessionByRoomCode(roomCode);
  
  final List<dynamic> categoriesData = session['categories'] ?? [];
  final categories = categoriesData.map((c) => Category.fromJson(c)).toList();
  print('Session has ${categories.length} categories: ${categories.map((c) => c.name).toList()}');
  
  final List<dynamic> questionsData = session['gameState']?['questions'] ?? [];
  final allQuestions = questionsData.map((q) => Question.fromJson(q)).toList();
  print('Session has ${allQuestions.length} questions in total');
  
  final questionsByCategory = <String, List<Question>>{};
  for (var cat in categories) {
    final catQuestions = allQuestions.where((q) {
      // Backend might return categoryId as an object if populated, or just string
      // Question.fromJson handles it if we adjust it, but let's check matches
      return q.categoryId == cat.id;
    }).toList();
    print('Category ${cat.name} (${cat.id}) has ${catQuestions.length} questions');
    questionsByCategory[cat.id] = catQuestions;
  }
  
  return BoardData(
    categories: categories,
    questionsByCategory: questionsByCategory,
  );
});
