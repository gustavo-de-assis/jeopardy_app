import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_models.dart';
import '../services/api_service.dart';

class BoardData {
  final List<Category> categories;
  final Map<String, List<Question>> questionsByCategory;

  BoardData({required this.categories, required this.questionsByCategory});
}

final boardDataProvider = FutureProvider<BoardData>((ref) async {
  final api = ref.read(apiServiceProvider);
  
  // 1. Fetch categories
  final categories = await api.getCategories();
  
  // 2. Fetch questions for these categories
  final categoryIds = categories.map((c) => c.id).toList();
  final allQuestions = await api.getQuestionsByCategories(categoryIds);
  
  // 3. Group questions by category
  final questionsByCategory = <String, List<Question>>{};
  for (var cat in categories) {
    questionsByCategory[cat.id] = allQuestions.where((q) => q.categoryId == cat.id).toList();
  }
  
  return BoardData(
    categories: categories,
    questionsByCategory: questionsByCategory,
  );
});
