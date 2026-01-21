import 'package:flutter/material.dart';
import 'category_column.dart';

class JeopardyGrid extends StatelessWidget {
  final Set<String> answeredQuestions;
  final Function(String id, String text) onQuestionSelected;

  const JeopardyGrid({
    super.key,
    required this.answeredQuestions,
    required this.onQuestionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        // color: Colors.black, // Dark background behind the grid removed for global gradient
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < 5; i++)
              CategoryColumn(
                categoryIndex: i,
                categoryName: "Category ${i + 1}",
                answeredQuestions: answeredQuestions,
                onQuestionSelected: onQuestionSelected,
              ),
          ],
        ),
      ),
    );
  }
}
