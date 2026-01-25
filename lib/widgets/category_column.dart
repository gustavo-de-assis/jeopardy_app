import 'package:flutter/material.dart';
import 'question_card.dart';
import '../models/game_models.dart';

class CategoryColumn extends StatelessWidget {
  final Category category;
  final List<Question> questions;
  final Set<String> answeredQuestions;
  final Function(String id, String text, String answer, int amount) onQuestionSelected;

  const CategoryColumn({
    super.key,
    required this.category,
    required this.questions,
    required this.answeredQuestions,
    required this.onQuestionSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Map questions by level for easy lookup
    final questionsByLevel = {
      for (var q in questions) q.level: q
    };

    return Expanded(
      child: Column(
        children: [
          // Category Header
          Container(
            height: 80,
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Color(int.parse(category.hexColor.replaceFirst('#', '0xFF'))),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Center(
              child: Text(
                category.name.toUpperCase(),
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
          // Questions (5 levels)
          for (var level = 1; level <= 5; level++)
            Builder(
              builder: (context) {
                final amount = level * 100;
                final question = questionsByLevel[level];
                final questionId = question?.id ?? "mock_${category.id}_$level";
                final isAnswered = answeredQuestions.contains(questionId);
                
                return QuestionCard(
                  amount: amount,
                  isAnswered: isAnswered,
                  onTap: () {
                    final questionText = question?.text ?? "This is a dummy question for ${category.name} at level $level (\$$amount).";
                    final answer = question?.answer ?? "Responsa corretamente!";
                    onQuestionSelected(questionId, questionText, answer, amount);
                  },
                );
              }
            ),
        ],
      ),
    );
  }
}
