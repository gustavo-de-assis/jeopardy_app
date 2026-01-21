import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/score_board.dart';
import '../widgets/jeopardy_grid.dart';

class GameRoomScreen extends StatefulWidget {
  const GameRoomScreen({super.key});

  @override
  State<GameRoomScreen> createState() => _GameRoomScreenState();
}

enum FinalJeopardyStage {
  none,
  intro,
  question,
  timeout,
}

class _GameRoomScreenState extends State<GameRoomScreen> {
  // State to track answered questions (using a simple ID format "catIndex_amount")
  final Set<String> _answeredQuestions = {};
  
  // State to track the currently selected question (null means showing the board)
  String? _currentQuestionText;
  String? _currentQuestionId;

  // Final Jeopardy State
  FinalJeopardyStage _finalJeopardyStage = FinalJeopardyStage.none;
  Timer? _timer;
  int _timeLeft = 30;

  bool get _allQuestionsAnswered => _answeredQuestions.length == 25;

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

  void _startFinalJeopardy() {
    setState(() {
      _finalJeopardyStage = FinalJeopardyStage.intro;
    });

    // 5 seconds intro
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() {
        _finalJeopardyStage = FinalJeopardyStage.question;
        _timeLeft = 30;
      });
      _startTimer();
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _finalJeopardyStage = FinalJeopardyStage.timeout;
        });
      }
    });
  }

  void _resetFinalJeopardy() {
     _timer?.cancel();
     setState(() {
       _finalJeopardyStage = FinalJeopardyStage.none;
     });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Final Jeopardy Views
    if (_finalJeopardyStage != FinalJeopardyStage.none) {
      return GestureDetector(
        onTap: _finalJeopardyStage == FinalJeopardyStage.timeout ? _resetFinalJeopardy : null,
        child: Container(
          color: Colors.transparent, 
           alignment: Alignment.center,
           padding: const EdgeInsets.all(32),
           child: Material(
             color: Colors.transparent,
             child: _buildFinalJeopardyContent(),
           ),
        ),
      );
    }

    // Normal Question View
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

    // Game Board
    return Scaffold(
      // backgroundColor: Colors.transparent, // Handled by theme now
      body: Row(
        children: [
          // Left Side: Score Column + Bonus Button
          SizedBox(
            width: 250,
            child: Column(
              children: [
                const ScoreBoard(),
                if (_allQuestionsAnswered) ...[
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32.0),
                    child: GestureDetector(
                      onTap: _startFinalJeopardy,
                      child: Container(
                        // ScoreBoard item structure: margin bottom 16 (we are separate), padding 4, gold border/bg
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700), // Gold border effect
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFFD700), width: 1),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            // QuestionCard gradient colors
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade800,
                                Colors.blue.shade900,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8), // Inner radius matching card? Or scoreboard? Scoreboard inner is 12 (but here outer is 8). Let's use 8.
                            border: Border.all(color: Colors.black54, width: 2), // QuestionCard border
                             boxShadow: const [
                              BoxShadow(
                                color: Colors.black45,
                                offset: Offset(2, 2),
                                blurRadius: 2,
                              )
                            ],
                          ),
                          child: const Text(
                            'BONUS',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFFFD700), // Gold text
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  offset: Offset(2, 2),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Main Content: Categories and Questions
          JeopardyGrid(
            answeredQuestions: _answeredQuestions,
            onQuestionSelected: _onQuestionSelected,
          ),
        ],
      ),
    );
  }

  Widget _buildFinalJeopardyContent() {
    switch (_finalJeopardyStage) {
      case FinalJeopardyStage.intro:
        return const Text(
          "PERGUNTA FINAL",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 64,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 4)],
          ),
        );
      case FinalJeopardyStage.question:
        return Stack(
          children: [
            const Center(
              child: Text(
                "Final Question Placeholder Text", // Logic for actual final question text if needed
                textAlign: TextAlign.center,
                 style: TextStyle(
                  color: Colors.white,
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 4)],
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              right: 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      color: Color(0xFFFFD700),
                      strokeWidth: 8,
                    ),
                  ),
                  Text(
                    "$_timeLeft",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      case FinalJeopardyStage.timeout:
         return const Text(
          "Acabou o tempo",
          textAlign: TextAlign.center,
           style: TextStyle(
            color: Colors.white,
            fontSize: 64,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 4)],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
