import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/score_board.dart';
import '../widgets/jeopardy_grid.dart';
import '../providers/game_providers.dart';
import '../services/socket_service.dart';

class GameRoomScreen extends ConsumerStatefulWidget {
  const GameRoomScreen({super.key});

  @override
  ConsumerState<GameRoomScreen> createState() => _GameRoomScreenState();
}

enum FinalJeopardyStage {
  none,
  intro,
  question,
  timeout,
}

class _GameRoomScreenState extends ConsumerState<GameRoomScreen> {
  final GameSocketService _socketService = GameSocketService();
  
  // State to track players
  List<dynamic> _players = [];
  String? _roomCode;
  String? _answeringPlayerNickname;
  String? _answeringPlayerSocketId;

  // State to track answered questions (using a simple ID format "catIndex_amount")
  final Set<String> _answeredQuestions = {};
  
  // State to track the currently selected question (null means showing the board)
  String? _currentQuestionText;
  String? _currentQuestionId;
  int? _currentQuestionAmount;

  // Final Jeopardy State
  FinalJeopardyStage _finalJeopardyStage = FinalJeopardyStage.none;
  Timer? _timer;
  int _timeLeft = 30;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && _roomCode == null) {
      setState(() {
        _roomCode = args['roomCode'];
        _players = args['players'] ?? [];
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _initSocket();
  }

  void _initSocket() {
    _socketService.initConnection();
    
    _socketService.onPlayerJoined = (data) {
      if (mounted) {
        setState(() {
          _players = data['players'] ?? [];
        });
      }
    };

    _socketService.onPlayerAnswering = (data) {
      if (mounted) {
        setState(() {
          _answeringPlayerNickname = data['nickname'];
          _answeringPlayerSocketId = data['socketId'];
        });
      }
    };

    _socketService.onRoundFinished = (data) {
      if (mounted) {
        setState(() {
          _players = data['players'] ?? _players;
          _answeringPlayerNickname = null;
          _answeringPlayerSocketId = null;
          // Automagically close the question when round is finished
          _onCloseQuestion();
        });
      }
    };

    _socketService.onBuzzReset = () {
      if (mounted) {
        setState(() {
          _answeringPlayerNickname = null;
          _answeringPlayerSocketId = null;
        });
      }
    };
  }

  bool get _allQuestionsAnswered => _answeredQuestions.length == 25;

  void _onQuestionSelected(String id, String questionText, int amount) {
    setState(() {
      _currentQuestionText = questionText;
      _currentQuestionId = id;
      _currentQuestionAmount = amount;
    });
    // Optional: emit to server that question was selected so it can reset buzzers
    if (_roomCode != null) {
      _socketService.resetBuzz(_roomCode!);
    }
  }

  void _onCloseQuestion() {
    if (_currentQuestionId != null) {
      setState(() {
        _answeredQuestions.add(_currentQuestionId!);
        _currentQuestionText = null;
        _currentQuestionId = null;
        _currentQuestionAmount = null;
      });
    }
  }

  void _judge(bool isCorrect) {
    if (_currentQuestionAmount == null || _roomCode == null) return;
    _socketService.judgeAnswer(_roomCode!, isCorrect, _currentQuestionAmount!);
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
    return Scaffold(
      body: Row(
        children: [
          // Left Side: Score Column + Bonus Button (Always visible)
          SizedBox(
            width: 250,
            child: Column(
              children: [
                ScoreBoard(players: _players),
                if (_allQuestionsAnswered && _finalJeopardyStage == FinalJeopardyStage.none) ...[
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32.0),
                    child: GestureDetector(
                      onTap: _startFinalJeopardy,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFFD700), width: 1),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue.shade800, Colors.blue.shade900],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black54, width: 2),
                            boxShadow: const [
                              BoxShadow(color: Colors.black45, offset: Offset(2, 2), blurRadius: 2)
                            ],
                          ),
                          child: const Text(
                            'BONUS',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              shadows: [Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 2)],
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
          
          // Right Side: Main Content (Grid or Question or Final Jeopardy)
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    // Final Jeopardy Views
    if (_finalJeopardyStage != FinalJeopardyStage.none) {
      return GestureDetector(
        onTap: _finalJeopardyStage == FinalJeopardyStage.timeout ? _resetFinalJeopardy : null,
        child: Container(
          color: Colors.transparent, 
          alignment: Alignment.center,
          padding: const EdgeInsets.all(32),
          child: _buildFinalJeopardyContent(),
        ),
      );
    }

    // Normal Question View
    if (_currentQuestionText != null) {
      return Container(
        color: Colors.transparent,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _currentQuestionText!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 64, 
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 4),
                ],
              ),
            ),
            const SizedBox(height: 48),
            if (_answeringPlayerNickname != null) ...[
              Text(
                "RESPONDENDO: ${_answeringPlayerNickname!.toUpperCase()}",
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildJudgeButton(label: "ERRADO", color: Colors.red, isCorrect: false),
                  const SizedBox(width: 32),
                  _buildJudgeButton(label: "CORRETO", color: Colors.green, isCorrect: true),
                ],
              ),
            ] else ...[
              const Text(
                 "AGUARDANDO BUZZ...",
                 style: TextStyle(color: Colors.white54, fontSize: 24, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _onCloseQuestion, 
                child: const Text("PULAR PERGUNTA"),
              ),
            ],
          ],
        ),
      );
    }

    // Game Board Grid
    return ref.watch(boardDataProvider).when(
      data: (boardData) => JeopardyGrid(
        categories: boardData.categories,
        questionsByCategoryId: boardData.questionsByCategory,
        answeredQuestions: _answeredQuestions,
        onQuestionSelected: _onQuestionSelected,
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("Error: $err")),
    );
  }

  Widget _buildJudgeButton({required String label, required Color color, required bool isCorrect}) {
    return ElevatedButton(
      onPressed: () => _judge(isCorrect),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      child: Text(label),
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
