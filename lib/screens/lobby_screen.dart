import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/socket_service.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  final GameSocketService _socketService = GameSocketService();
  
  // State
  bool _isHost = false;
  String? _roomCode;
  String? _nickname;
  String? _userId;
  bool _hasJoined = false;
  List<dynamic> _players = [];
  
  // Controller for inputs
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nickController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _isHost = args['isHost'] ?? false;
      _roomCode = args['roomCode'];
      if (_isHost && _roomCode != null && !_hasJoined) {
        _hasJoined = true;
        // Host joins their own room via socket to listen for events
        _userId = args['userId'] ?? "host_user_123";
        _socketService.joinRoom(_roomCode!, "HOST", userId: _userId);
      }
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

    _socketService.onGameStarted = () {
      if (mounted) {
        // Only the Web Host goes to the Board. 
        // Players AND the Mobile Host go to the Mobile Controller.
        final nextRoute = (kIsWeb && _isHost) ? '/game' : '/mobile-game';
        
        Navigator.of(context).pushReplacementNamed(
          nextRoute,
          arguments: {
            'roomCode': _roomCode,
            'players': _players,
            'isHost': _isHost,
          }
        );
      }
    };
  }

  void _handleJoin() {
    final code = _codeController.text.trim().toUpperCase();
    final nick = _nickController.text.trim();
    final uid = _userIdController.text.trim();

    if (code.isEmpty || nick.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha todos os campos")),
      );
      return;
    }

    _nickname = nick;
    _roomCode = code;
    _userId = uid.isNotEmpty ? uid : null;
    
    _socketService.joinRoom(code, nick, userId: _userId, onResponse: (data) {
      if (mounted && data['success'] == true) {
        setState(() {
          _isHost = data['role'] == 'HOST';
          _hasJoined = true;
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao entrar: ${data['message']}")),
        );
      }
    });
  }

  void _handleStartGame() {
    if (_roomCode != null) {
      _socketService.startGame(_roomCode!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isHost ? "LOBBY DO HOST" : "ENTRAR NA SALA"),
        centerTitle: true,
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: _hasJoined ? _buildWaitingRoom() : _buildJoinForm(),
        ),
      ),
    );
  }

  Widget _buildJoinForm() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _codeController,
            decoration: const InputDecoration(
              labelText: "CÓDIGO DA SALA (4 letras)",
              border: OutlineInputBorder(),
              labelStyle: TextStyle(color: Colors.white),
            ),
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            maxLength: 4,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nickController,
            decoration: const InputDecoration(
              labelText: "SEU NICKNAME",
              border: OutlineInputBorder(),
              labelStyle: TextStyle(color: Colors.white),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _userIdController,
            decoration: const InputDecoration(
              labelText: "USER ID (OPCIONAL PARA HOST)",
              border: OutlineInputBorder(),
              labelStyle: TextStyle(color: Colors.white),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _handleJoin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text("ENTRAR NO JOGO", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingRoom() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_isHost) ...[
          const Text("CÓDIGO DA SALA", style: TextStyle(color: Colors.white70, fontSize: 18)),
          Text(
            _roomCode ?? "----",
            style: const TextStyle(color: Color(0xFFFFD700), fontSize: 80, fontWeight: FontWeight.w900, letterSpacing: 8),
          ),
          const SizedBox(height: 48),
        ] else ...[
          const Icon(Icons.timer_outlined, size: 80, color: Color(0xFFFFD700)),
          const SizedBox(height: 24),
          Text(
            "OLÁ, ${_nickname?.toUpperCase()}!",
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Text("AGUARDANDO O HOST COMEÇAR...", style: TextStyle(color: Colors.white54, fontSize: 16)),
          const SizedBox(height: 48),
        ],
        
        const Text("JOGADORES CONECTADOS:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _players.map((p) => Chip(
            label: Text(p['nickname'] ?? '?', style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.blue[800],
            labelStyle: const TextStyle(color: Colors.white),
            side: const BorderSide(color: Color(0xFFFFD700)),
          )).toList(),
        ),

        if (_players.isEmpty)
          const Text("Nenhum jogador ainda...", style: TextStyle(color: Colors.white24, fontStyle: FontStyle.italic)),

        const Spacer(),
        
        if (_isHost)
          ElevatedButton(
            onPressed: _players.isEmpty ? null : _handleStartGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text("COMEÇAR JOGO!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }
}
