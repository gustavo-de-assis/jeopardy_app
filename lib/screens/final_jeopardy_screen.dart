import 'dart:async';
import 'package:flutter/material.dart';
import '../services/socket_service.dart';
import 'game_over_screen.dart';

enum FinalJeopardyPhase {
  wagering,
  answering,
  judging,
}

class FinalJeopardyScreen extends StatefulWidget {
  final String roomCode;
  final bool isHost;
  final bool isMobile; // To distinguish between Web Board and Mobile Player/Host
  final String? questionType; // STANDARD or APPROXIMATION
  final List<dynamic> players; // For Web Board display and Host judging
  final List<dynamic> categories; // Categories in play for host selection
  final String? userId; // For Player identification

  const FinalJeopardyScreen({
    super.key,
    required this.roomCode,
    required this.isHost,
    this.isMobile = true,
    this.questionType = 'STANDARD',
    required this.players,
    required this.categories,
    this.userId,
  });

  @override
  State<FinalJeopardyScreen> createState() => _FinalJeopardyScreenState();
}

class _FinalJeopardyScreenState extends State<FinalJeopardyScreen> {
  final GameSocketService _socketService = GameSocketService();
  
  FinalJeopardyPhase _phase = FinalJeopardyPhase.wagering;
  String? _finalQuestionText;
  String? _selectedCategoryName;
  String? _currentQuestionType;
  
  // Wager State
  final TextEditingController _wagerController = TextEditingController();
  bool _wagerSubmitted = false;
  int _myScore = 0;
  final Set<String> _readyPlayerIds = {}; // Players who submitted wager

  // Answer State
  final TextEditingController _answerController = TextEditingController();
  bool _answerSubmitted = false;
  int _timeLeft = 30;
  Timer? _timer;

  // Host/Board Judging State
  List<dynamic> _playerAnswers = [];
  String? _correctAnswer;
  final Set<String> _revealedPlayerIds = {};
  final Map<String, bool> _standardResults = {}; // { playerId: isCorrect }
  final Set<String> _approximationWinners = {}; // { playerId }
  
  // Let's implement what we can.
  
  @override
  void initState() {
    super.initState();
    if (widget.userId != null) {
      final me = widget.players.firstWhere((p) => p['socketId'] == widget.userId || p['id'] == widget.userId, orElse: () => {'score': 0});
      _myScore = me['score'] ?? 0;
    }
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    _socketService.onAllWagersPlaced = () {
      if (mounted) {
        setState(() {}); // Refresh to show "Reveal Question" button if Host
      }
    };

    _socketService.onWagerConfirmed = (data) {
      if (mounted) {
        setState(() {
          _readyPlayerIds.add(data['playerId']);
        });
      }
    };

    _socketService.onFinalCategorySelected = (data) {
      if (mounted) {
        setState(() {
          _selectedCategoryName = data['categoryName'];
          _currentQuestionType = data['questionType'];
        });
      }
    };

    _socketService.onShowFinalQuestion = (data) {
      if (mounted) {
        setState(() {
          _phase = FinalJeopardyPhase.answering;
          _finalQuestionText = data['text'];
          _timeLeft = data['duration'] ?? 30;
        });
        _startTimer();
      }
    };

    _socketService.onJudgingPhaseStarted = (data) {
      if (mounted) {
        setState(() {
          _phase = FinalJeopardyPhase.judging;
          _timer?.cancel();
          _playerAnswers = data['playerAnswers'] ?? [];
          _correctAnswer = data['correctAnswer'];
          _currentQuestionType = data['questionType'] ?? widget.questionType;
        });
      }
    };

    _socketService.onAnswerRevealedOnBoard = (data) {
      if (mounted) {
        setState(() {
          _revealedPlayerIds.add(data['playerId']);
          // Update the answer text in _playerAnswers if it's there
          final idx = _playerAnswers.indexWhere((pa) => pa['playerId'] == data['playerId']);
          if (idx != -1) {
            _playerAnswers[idx]['answerText'] = data['answerText'];
            _playerAnswers[idx]['isRevealed'] = true;
          }
        });
      }
    };

    _socketService.onGameOver = (data) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => GameOverScreen(
              leaderboard: data['leaderboard'],
              isHost: widget.isHost,
              roomCode: widget.roomCode,
            ),
          ),
        );
      }
    };
  }

  void _selectCategory(String categoryId, String categoryName) {
    _socketService.socket?.emit('select_final_category', {
      'roomCode': widget.roomCode,
      'categoryId': categoryId,
      'categoryName': categoryName,
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        timer.cancel();
        if (widget.isMobile && !widget.isHost && !_answerSubmitted) {
          _submitAnswer();
        }
        if (widget.isHost && _phase == FinalJeopardyPhase.answering) {
          _socketService.startJudging(widget.roomCode);
        }
      }
    });
  }

  void _submitWager() {
    final amount = int.tryParse(_wagerController.text);
    if (amount != null && amount >= 0 && amount <= _myScore) {
      _socketService.submitWager(widget.roomCode, amount);
      setState(() {
        _wagerSubmitted = true;
      });
    } else {
      String msg = "Aposta inválida!";
      if (amount != null && amount > _myScore) msg = "Você não tem pontos suficientes!";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _submitAnswer() {
    _socketService.submitFinalAnswer(widget.roomCode, _answerController.text);
    setState(() {
      _answerSubmitted = true;
    });
  }

  Widget _buildWageringUI() {
    if (widget.isHost) {
      if (_selectedCategoryName == null) {
        return Column(
          children: [
            const Text(
              "SELECIONE A CATEGORIA FINAL",
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: widget.categories.length,
                itemBuilder: (context, index) {
                  final cat = widget.categories[index];
                  return Card(
                    color: Colors.white10,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(cat['name'], style: const TextStyle(color: Colors.white)),
                      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.amber, size: 16),
                      onTap: () => _selectCategory(cat['_id'], cat['name']),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "CATEGORIA: ${_selectedCategoryName!.toUpperCase()}",
              style: const TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Aguardando apostas dos jogadores...",
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                _socketService.revealFinalQuestion(widget.roomCode);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text("REVELAR PERGUNTA", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    if (_wagerSubmitted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_selectedCategoryName != null) ...[
              Text(
                "CATEGORIA: ${_selectedCategoryName!.toUpperCase()}",
                style: const TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
            ],
            const CircularProgressIndicator(color: Colors.amber),
            const SizedBox(height: 20),
            const Text("Aposta confirmada! Aguardando...", style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_selectedCategoryName != null) ...[
          Text(
            "CATEGORIA: ${_selectedCategoryName!.toUpperCase()}",
            style: const TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
        ] else ...[
          const Text("O Host está escolhendo a categoria...", style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)),
          const SizedBox(height: 32),
        ],
        const Text("Quanto você quer apostar?", style: TextStyle(color: Colors.white, fontSize: 20)),
        const SizedBox(height: 16),
        TextField(
          controller: _wagerController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixText: "\$",
            prefixStyle: TextStyle(color: Colors.amber),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _selectedCategoryName != null ? _submitWager : null,
          child: const Text("APOSTAR"),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isMobile) {
      return _buildWebBoardView();
    }
    if (widget.isHost) {
      return _buildHostMobileView();
    }
    return _buildPlayerMobileView();
  }

  // --------------------------------------------------------------------------
  // WEB BOARD VIEW
  // --------------------------------------------------------------------------
  Widget _buildWebBoardView() {
    return Scaffold(
      backgroundColor: Colors.black, // Deep Blue/Black bg
      body: Center(
        child: _buildWebContent(),
      ),
    );
  }

  Widget _buildWebContent() {
    switch (_phase) {
      case FinalJeopardyPhase.wagering:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("FINAL JEOPARDY", style: TextStyle(color: Colors.white, fontSize: 48, fontFamily: 'itc-korinna')),
            const SizedBox(height: 32),
            if (_selectedCategoryName != null) ...[
              Text(
                "CATEGORIA: ${_selectedCategoryName!.toUpperCase()}",
                style: const TextStyle(color: Colors.amber, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
            ],
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 32),
            Text(
              _selectedCategoryName == null ? "O Host está escolhendo a categoria..." : "Façam suas apostas...", 
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 24)
            ),
            const SizedBox(height: 48),
            Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: widget.players.map((p) {
                   final bool ready = _readyPlayerIds.contains(p['socketId']) || _readyPlayerIds.contains(p['id']);
                   return Container(
                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                     decoration: BoxDecoration(
                       color: ready ? Colors.green[900]?.withOpacity(0.5) : Colors.blue[900]?.withOpacity(0.5),
                       border: Border.all(color: ready ? Colors.green : Colors.blue),
                       borderRadius: BorderRadius.circular(8),
                     ),
                     child: Column(
                       children: [
                         Text(
                           p['nickname'] ?? 'Player',
                           style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                         ),
                         Text(
                           ready ? "PRONTO" : "PENSANDO...",
                           style: TextStyle(color: ready ? Colors.green : Colors.white54, fontSize: 12),
                         ),
                       ],
                     ),
                   );
                }).toList(),
              ),
            ),
          ],
        );
      case FinalJeopardyPhase.answering:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Text(_finalQuestionText ?? "", 
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 48, fontFamily: 'itc-korinna', fontWeight: FontWeight.bold)
            ),
             const SizedBox(height: 64),
            Text("$_timeLeft", style: const TextStyle(color: Colors.red, fontSize: 80, fontWeight: FontWeight.bold)),
          ],
        );
      case FinalJeopardyPhase.judging:
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text(
                "HORA DA VERDADE", 
                style: TextStyle(color: Colors.amber, fontSize: 48, fontWeight: FontWeight.bold, fontFamily: 'itc-korinna')
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 100),
                  child: Wrap(
                    spacing: 40,
                    runSpacing: 40,
                    alignment: WrapAlignment.center,
                    children: _playerAnswers.map((pa) {
                      final bool revealed = _revealedPlayerIds.contains(pa['playerId']) || pa['isRevealed'] == true;
                      return Container(
                        width: 400,
                        height: 250,
                        decoration: BoxDecoration(
                          color: Colors.blue[900],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(4, 4))],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              pa['nickname']?.toUpperCase() ?? 'PLAYER',
                              style: const TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const Divider(color: Colors.white24, indent: 40, endIndent: 40),
                            const SizedBox(height: 20),
                            if (!revealed)
                              const Text(
                                "???", 
                                style: TextStyle(color: Colors.white38, fontSize: 64, fontWeight: FontWeight.w900, letterSpacing: 8)
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  pa['answerText'] ?? 'Nenhuma resposta',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                                ),
                              ),
                            const SizedBox(height: 10),
                            if (revealed)
                              Text(
                                "APOSTA: \$${pa['wager']}",
                                style: const TextStyle(color: Colors.white54, fontSize: 18),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
    }
    return const SizedBox();
  }

  // --------------------------------------------------------------------------
  // PLAYER MOBILE VIEW
  // --------------------------------------------------------------------------
  Widget _buildPlayerMobileView() {
    return Scaffold(
      appBar: AppBar(title: Text("Sua Pontuação: \$$_myScore")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _buildPlayerContent(),
      ),
    );
  }

  Widget _buildPlayerContent() {
    switch (_phase) {
      case FinalJeopardyPhase.wagering:
        return _buildWageringUI();
      case FinalJeopardyPhase.answering:
         if (_answerSubmitted) {
          return const Center(child: Text("Resposta enviada!", style: TextStyle(fontSize: 24)));
        }
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Text(
               _finalQuestionText ?? "", 
               textAlign: TextAlign.center,
               style: const TextStyle(fontSize: 24, fontStyle: FontStyle.italic, color: Colors.white)
             ),
             const SizedBox(height: 32),
             Stack(
               alignment: Alignment.center,
               children: [
                 SizedBox(
                   width: 120,
                   height: 120,
                   child: CircularProgressIndicator(
                     value: _timeLeft / 30,
                     strokeWidth: 10,
                     color: _timeLeft < 10 ? Colors.red : Colors.blue,
                     backgroundColor: Colors.white10,
                   ),
                 ),
                 Text(
                   "$_timeLeft", 
                   style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)
                 ),
               ],
             ),
             const SizedBox(height: 32),
             TextField(
              controller: _answerController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                border: OutlineInputBorder(), 
                hintText: "Sua resposta...",
                hintStyle: TextStyle(color: Colors.white54),
              ),
            ),
             const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitAnswer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text("ENVIAR RESPOSTA", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      case FinalJeopardyPhase.judging:
        return const Center(child: Text("O Host está julgando...", style: TextStyle(fontSize: 24)));
    }
  }

  // --------------------------------------------------------------------------
  // HOST MOBILE VIEW
  // --------------------------------------------------------------------------
  Widget _buildHostMobileView() {
    return Scaffold(
      appBar: AppBar(title: const Text("Controle do Host - Final")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildHostContent(),
      ),
    );
  }

   Widget _buildHostContent() {
     switch (_phase) {
      case FinalJeopardyPhase.wagering:
        return _buildWageringUI();
      case FinalJeopardyPhase.answering:
        return Center(
           child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("$_timeLeft", style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
               ElevatedButton(
                onPressed: () => _socketService.startJudging(widget.roomCode), 
                child: const Text("ENCERRAR TEMPO & JULGAR")
              ),
            ],
           )
        );
      case FinalJeopardyPhase.judging:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.green[900], borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("RESPOSTA CORRETA:", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_correctAnswer ?? "...", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _playerAnswers.length,
                itemBuilder: (context, index) {
                  final pa = _playerAnswers[index];
                  final playerId = pa['playerId'];
                  final bool revealed = _revealedPlayerIds.contains(playerId) || pa['isRevealed'] == true;
                  
                  return Card(
                    color: Colors.white10,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("${pa['nickname']} (\$${pa['wager']})", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(pa['answerText'] ?? 'Sem resposta', style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(revealed ? Icons.visibility : Icons.visibility_off, color: revealed ? Colors.blue : Colors.white54),
                                onPressed: () => _socketService.revealAnswerToRoom(widget.roomCode, playerId),
                                tooltip: "Revelar no Telão",
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white10),
                          if (_currentQuestionType == 'STANDARD')
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildJudgeBtn(Icons.close, Colors.red, _standardResults[playerId] == false, () {
                                  setState(() => _standardResults[playerId] = false);
                                }),
                                _buildJudgeBtn(Icons.check, Colors.green, _standardResults[playerId] == true, () {
                                  setState(() => _standardResults[playerId] = true);
                                }),
                              ],
                            )
                          else
                            _buildJudgeBtn(Icons.workspace_premium, Colors.amber, _approximationWinners.contains(playerId), () {
                              setState(() {
                                if (_approximationWinners.contains(playerId)) {
                                  _approximationWinners.remove(playerId);
                                } else {
                                  _approximationWinners.add(playerId);
                                }
                              });
                            }, label: "VENCEDOR"),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitResults,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber, 
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16)
                ),
                child: const Text("ENVIAR RESULTADOS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ),
          ],
        );
    }
   }

   Widget _buildJudgeBtn(IconData icon, Color color, bool active, VoidCallback onTap, {String? label}) {
     return InkWell(
       onTap: onTap,
       child: Container(
         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
         decoration: BoxDecoration(
           color: active ? color : Colors.transparent,
           border: Border.all(color: color, width: 2),
           borderRadius: BorderRadius.circular(20),
         ),
         child: Row(
           mainAxisSize: MainAxisSize.min,
           children: [
             Icon(icon, color: active ? Colors.black : color, size: 20),
             if (label != null) ...[
               const SizedBox(width: 8),
               Text(label, style: TextStyle(color: active ? Colors.black : color, fontWeight: FontWeight.bold)),
             ],
           ],
         ),
       ),
     );
   }

   void _submitResults() {
     if (_currentQuestionType == 'STANDARD') {
       final results = _playerAnswers.map((pa) {
         final pid = pa['playerId'];
         return {'playerId': pid, 'isCorrect': _standardResults[pid] ?? false};
       }).toList();
       _socketService.resolveStandardRound(widget.roomCode, results);
     } else {
       _socketService.resolveApproximationWinner(widget.roomCode, _approximationWinners.toList());
     }
   }
}
