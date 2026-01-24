import 'package:flutter/material.dart';
import 'category_column.dart';
import '../models/game_models.dart';

class JeopardyGrid extends StatelessWidget {
  final List<Category> categories;
  final Map<String, List<Question>> questionsByCategoryId;
  final Set<String> answeredQuestions;
  final Function(String id, String text, int amount) onQuestionSelected;

  const JeopardyGrid({
    super.key,
    required this.categories,
    required this.questionsByCategoryId,
    required this.answeredQuestions,
    required this.onQuestionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var category in categories)
            CategoryColumn(
              category: category,
              questions: questionsByCategoryId[category.id] ?? [],
              answeredQuestions: answeredQuestions,
              onQuestionSelected: onQuestionSelected,
            ),
        ],
      ),
    );
  }
}
