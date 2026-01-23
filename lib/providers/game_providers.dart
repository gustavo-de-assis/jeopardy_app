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
  
  print('Fetching categories...');
  final categories = await api.getCategories();
  print('Found ${categories.length} categories: ${categories.map((c) => c.name).toList()}');
  
  final categoryIds = categories.map((c) => c.id).toList();
  print('Fetching questions for category IDs: $categoryIds');
  final allQuestions = await api.getQuestionsByCategories(categoryIds);
  print('Fetched ${allQuestions.length} questions in total');
  
  final questionsByCategory = <String, List<Question>>{};
  for (var cat in categories) {
    final catQuestions = allQuestions.where((q) {
      final match = q.categoryId == cat.id;
      return match;
    }).toList();
    print('Category ${cat.name} (${cat.id}) has ${catQuestions.length} questions');
    questionsByCategory[cat.id] = catQuestions;
  }
  
  return BoardData(
    categories: categories,
    questionsByCategory: questionsByCategory,
  );
});
