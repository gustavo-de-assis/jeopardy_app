import 'package:flutter/material.dart';
import 'question_card.dart';

class CategoryColumn extends StatelessWidget {
  final int categoryIndex;
  final String categoryName;
  final Set<String> answeredQuestions;
  final Function(String id, String text) onQuestionSelected;

  const CategoryColumn({
    super.key,
    required this.categoryIndex,
    required this.categoryName,
    required this.answeredQuestions,
    required this.onQuestionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          // Category Header
          Container(
            height: 80,
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.blue[800],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Center(
              child: Text(
                categoryName.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      offset: Offset(1, 1),
                      blurRadius: 1,
                    )
                  ],
                ),
              ),
            ),
          ),
          // Questions
          for (var i = 1; i <= 5; i++)
            Builder(
              builder: (context) {
                final amount = i * 100;
                final questionId = "cat${categoryIndex}_$amount";
                final isAnswered = answeredQuestions.contains(questionId);
                
                return QuestionCard(
                  amount: amount,
                  isAnswered: isAnswered,
                  onTap: () {
                    // Example question text
                    final questionText = "This is a dummy question for $categoryName for \$$amount.";
                    onQuestionSelected(questionId, questionText);
                  },
                );
              }
            ),
        ],
      ),
    );
  }
}
