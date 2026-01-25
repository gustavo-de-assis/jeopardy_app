import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/socket_service.dart';

class MobileGameScreen extends ConsumerStatefulWidget {
  const MobileGameScreen({super.key});

  @override
  ConsumerState<MobileGameScreen> createState() => _MobileGameScreenState();
}

class _MobileGameScreenState extends ConsumerState<MobileGameScreen> {
  final GameSocketService _socketService = GameSocketService();
  
  // Arguments
  late String _roomCode;
  late bool _isHost;
  
  // Game State
  Map<String, dynamic>? _currentQuestion;
  String? _answeringPlayerNickname;
  String? _answeringPlayerSocketId;
  int? _queuePosition;
  bool _isMyTurn = false;

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
    _initSocket();
  }

  void _initSocket() {
    _socketService.onQuestionOpened = (data) {
      if (mounted) {
        setState(() {
          _currentQuestion = data;
          _answeringPlayerNickname = null;
          _answeringPlayerSocketId = null;
          _queuePosition = null;
          _isMyTurn = false;
        });
      }
    };

    _socketService.onPlayerAnswering = (data) {
      if (mounted) {
        final socketId = data['socketId'];
        setState(() {
          _answeringPlayerNickname = data['nickname'];
          _answeringPlayerSocketId = socketId;
          _isMyTurn = socketId == _socketService.socket?.id;
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
          _answeringPlayerSocketId = null;
          _queuePosition = null;
          _isMyTurn = false;
        });
      }
    };

    _socketService.onBuzzReset = () {
      if (mounted) {
        setState(() {
          _answeringPlayerNickname = null;
          _answeringPlayerSocketId = null;
          _queuePosition = null;
        });
      }
    };
  }

  void _buzz() {
    _socketService.buzz(_roomCode);
  }

  void _judge(bool isCorrect) {
    if (_currentQuestion == null) return;
    _socketService.judgeAnswer(_roomCode, isCorrect, _currentQuestion!['amount']);
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
            style: const TextStyle(fontSize: 20, fontStyle: FontStyle.italic),
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

    if (_answeringPlayerNickname != null) {
       return _buildCenteredMessage("${_answeringPlayerNickname} está respondendo...");
    }

    return Center(
      child: GestureDetector(
        onTap: _buzz,
        child: Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 20, spreadRadius: 5),
            ],
            border: Border.all(color: Colors.white, width: 8),
          ),
          child: const Center(
            child: Text(
              "BUZZ",
              style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
          ),
        ),
      ),
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
