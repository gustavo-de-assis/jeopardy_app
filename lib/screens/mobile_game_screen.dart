import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/socket_service.dart';
import '../services/sound_service.dart';
import 'final_jeopardy_screen.dart';

class MobileGameScreen extends ConsumerStatefulWidget {
  const MobileGameScreen({super.key});

  @override
  ConsumerState<MobileGameScreen> createState() => _MobileGameScreenState();
}

class _MobileGameScreenState extends ConsumerState<MobileGameScreen> with SingleTickerProviderStateMixin {
  final GameSocketService _socketService = GameSocketService();
  
  // Arguments
  late String _roomCode;
  late bool _isHost;
  
  // Game State
  Map<String, dynamic>? _currentQuestion;
  String? _answeringPlayerNickname;
  int? _queuePosition;
  bool _isMyTurn = false;
  
  // Buzzer Entry Window (10s)
  late AnimationController _buzzAnimationController;
  bool _isBuzzerWindowOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _roomCode = args['roomCode'] ?? '';
      _isHost = args['isHost'] ?? false;
    }
  }

  @override
  void initState() {
    super.initState();
    _buzzAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _isBuzzerWindowOpen = false;
          });
        }
      }
    });
    _initSocket();
  }

  void _initSocket() {
    _socketService.onQuestionOpened = (data) {
      if (mounted) {
        setState(() {
          _currentQuestion = data;
          _answeringPlayerNickname = null;
          _queuePosition = null;
          _isMyTurn = false;
          _startBuzzerWindow();
        });
      }
    };

    _socketService.onPlayerAnswering = (data) {
      if (mounted) {
        final socketId = data['socketId'];
        final isMe = socketId == _socketService.socket?.id;
        
        // Only play buzzer sound and haptic if this is the first person to buzz in the round
        if (isMe && _answeringPlayerNickname == null) {
          SoundService().playBuzzer();
          HapticFeedback.lightImpact();
        }

        setState(() {
          _answeringPlayerNickname = data['nickname'];
          _isMyTurn = isMe;
          if (_isMyTurn) _queuePosition = null;
        });
      }
    };

    _socketService.onQueueUpdated = (data) {
      if (mounted) {
        setState(() {
          _queuePosition = data['position'];
        });
      }
    };

    _socketService.onRoundFinished = (data) {
      if (mounted) {
        setState(() {
          _currentQuestion = null;
          _answeringPlayerNickname = null;
          _queuePosition = null;
          _isMyTurn = false;
          _stopBuzzerWindow();
        });
      }
    };

    _socketService.onBuzzReset = () {
      if (mounted) {
        setState(() {
          _answeringPlayerNickname = null;
          _queuePosition = null;
          _stopBuzzerWindow();
        });
      }
    };

    _socketService.onFinalPhaseStarted = (data) {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FinalJeopardyScreen(
              roomCode: _roomCode, 
              isHost: _isHost,
              isMobile: true,
              questionType: data['questionType'], // passed from server
              players: [], // Not needed for player view mostly, or we could pass if we had it
            ),
          ),
        );
      }
    };
  }

  void _startBuzzerWindow() {
    _isBuzzerWindowOpen = true;
    _buzzAnimationController.reset();
    _buzzAnimationController.forward();
  }

  void _stopBuzzerWindow() {
    _isBuzzerWindowOpen = false;
    _buzzAnimationController.stop();
  }

  void _buzz() {
    if (!_isBuzzerWindowOpen) return;
    _socketService.buzz(_roomCode);
  }

  void _judge(bool isCorrect) {
    if (_currentQuestion == null) return;
    
    if (isCorrect) {
      SoundService().playCorrect();
    } else {
      SoundService().playWrong();
    }
    
    _socketService.judgeAnswer(_roomCode, isCorrect, _currentQuestion!['amount']);
  }

  @override
  void dispose() {
    _buzzAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isHost ? "CONTROLE DO HOST" : "BUZZER"),
        centerTitle: true,
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: _isHost ? _buildHostUI() : _buildPlayerUI(),
      ),
    );
  }

  Widget _buildHostUI() {
    if (_currentQuestion == null) {
      return _buildCenteredMessage("Escolhendo pergunta...");
    }

    if (_answeringPlayerNickname != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "JOGADOR: ${_answeringPlayerNickname!.toUpperCase()}",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFFFD700)),
          ),
          const SizedBox(height: 16),
          Text(
            _currentQuestion!['text'],
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'itc-korinna',
              fontSize: 20,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "RESPOSTA: ${_currentQuestion!['answer'] ?? 'Unknown'}",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, color: Colors.white70, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 48),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: "ERRADO",
                  color: Colors.red,
                  onPressed: () => _judge(false),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(
                  label: "CORRETO",
                  color: Colors.green,
                  onPressed: () => _judge(true),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return _buildCenteredMessage("Aguardando alguém apertar o botão...");
  }

  Widget _buildPlayerUI() {
    if (_currentQuestion == null) {
      return _buildCenteredMessage("Olhos no telão...");
    }

    if (_isMyTurn) {
      return _buildCenteredMessage("SUA VEZ! RESPONDA AGORA!", color: const Color(0xFFFFD700));
    }

    if (_queuePosition != null) {
      return _buildCenteredMessage("Você está em #${_queuePosition} na fila...");
    }

    final bool someoneElseAnswering = _answeringPlayerNickname != null;
    
    // If no one is answering AND time is up
    if (!_isBuzzerWindowOpen && !someoneElseAnswering) {
       return _buildCenteredMessage("NINGUÉM APERTOU NO TEMPO!");
    }

    // Main Button Logic
    Color buttonColor = Colors.red;
    String buttonText = "BUZZ";
    
    if (someoneElseAnswering && _isBuzzerWindowOpen) {
      buttonColor = Colors.orange;
      buttonText = "ENTRAR NA FILA!";
    } else if (!_isBuzzerWindowOpen) {
      buttonColor = Colors.grey;
      buttonText = "FECHADO";
    }

    return Column(
      children: [
        Expanded(
          child: Center(
            child: GestureDetector(
              onTap: _isBuzzerWindowOpen ? _buzz : null,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: buttonColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (_isBuzzerWindowOpen)
                      BoxShadow(color: buttonColor.withOpacity(0.4), blurRadius: 20, spreadRadius: 5),
                  ],
                  border: Border.all(color: Colors.white, width: 8),
                ),
                child: Center(
                  child: Text(
                    buttonText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white, 
                      fontSize: buttonText.length > 5 ? 24 : 48, 
                      fontWeight: FontWeight.w900, 
                      letterSpacing: 2
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_isBuzzerWindowOpen)
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: AnimatedBuilder(
              animation: _buzzAnimationController,
              builder: (context, child) {
                final double remainingSeconds = 10 * (1.0 - _buzzAnimationController.value);
                // Cycle color from green to yellow to red
                Color progressColor = Colors.green;
                if (_buzzAnimationController.value > 0.7) {
                  progressColor = Colors.red;
                } else if (_buzzAnimationController.value > 0.4) {
                  progressColor = Colors.amber;
                }

                return Column(
                  children: [
                    Text(
                      "JANELA DE ENTRADA: ${remainingSeconds.toStringAsFixed(1)}s",
                      style: TextStyle(
                        color: progressColor.withOpacity(0.9), 
                        fontSize: 14, 
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2
                      ),
                    ),
                    const SizedBox(height: 12),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 54,
                          height: 54,
                          child: CircularProgressIndicator(
                            value: 1.0 - _buzzAnimationController.value,
                            strokeWidth: 5,
                            color: progressColor,
                            backgroundColor: Colors.white10,
                          ),
                        ),
                        const Icon(Icons.timer_outlined, color: Colors.white30, size: 20),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCenteredMessage(String message, {Color color = Colors.white70}) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildActionButton({required String label, required Color color, required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }
}
