import 'package:flutter/material.dart';
import '../widgets/score_board.dart';
import '../widgets/jeopardy_grid.dart';

class GameRoomScreen extends StatefulWidget {
  const GameRoomScreen({super.key});

  @override
  State<GameRoomScreen> createState() => _GameRoomScreenState();
}

class _GameRoomScreenState extends State<GameRoomScreen> {
  // State to track answered questions (using a simple ID format "catIndex_amount")
  final Set<String> _answeredQuestions = {};
  
  // State to track the currently selected question (null means showing the board)
  String? _currentQuestionText;
  String? _currentQuestionId;

  void _onQuestionSelected(String id, String questionText) {
    setState(() {
      _currentQuestionText = questionText;
      _currentQuestionId = id;
    });
  }

  void _onCloseQuestion() {
    if (_currentQuestionId != null) {
      setState(() {
        _answeredQuestions.add(_currentQuestionId!);
        _currentQuestionText = null;
        _currentQuestionId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If a question is selected, show it full screen
    if (_currentQuestionText != null) {
      return GestureDetector(
        onTap: _onCloseQuestion,
        child: Container(
          color: Colors.transparent, // Let gradient show through
          alignment: Alignment.center,
          padding: const EdgeInsets.all(32),
          child: Material(
            color: Colors.transparent,
            child: Text(
              _currentQuestionText!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 64, // Increased size
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    offset: Offset(2, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Otherwise show the game board
    return Scaffold(
      // backgroundColor: Colors.transparent, // Handled by theme now
      body: Row(
        children: [
          // Left Side: Score Column
          const ScoreBoard(),
          
          // Main Content: Categories and Questions
          JeopardyGrid(
            answeredQuestions: _answeredQuestions,
            onQuestionSelected: _onQuestionSelected,
          ),
        ],
      ),
    );
  }
}
