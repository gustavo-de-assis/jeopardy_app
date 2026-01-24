import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';

class GameSocketService {
  // Singleton pattern
  static final GameSocketService _instance = GameSocketService._internal();
  factory GameSocketService() => _instance;
  GameSocketService._internal();

  late IO.Socket socket;
  
  // Callbacks for UI updates
  Function(Map<String, dynamic>)? onPlayerJoined;
  Function(Map<String, dynamic>)? onPlayerAnswering;
  Function(Map<String, dynamic>)? onRoundFinished;
  Function(Map<String, dynamic>)? onQueueUpdated;
  Function()? onBuzzReset;

  void initConnection() {
    // Current machine IP from previous investigation
    // const String baseUrl = 'http://192.168.1.67:3000';
    const String baseUrl = 'http://localhost:3000';
    
    socket = IO.io(baseUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect() 
        .build());

    socket.connect();
    _setupListeners();
  }

  void _setupListeners() {
    socket.onConnect((_) {
      debugPrint('Conectado ao Backend: ${socket.id}');
    });

    socket.onDisconnect((_) => debugPrint('Desconectado do Backend'));

    socket.on('player_joined', (data) {
      if (onPlayerJoined != null) onPlayerJoined!(data);
    });
    
    socket.on('player_answering', (data) {
      if (onPlayerAnswering != null) onPlayerAnswering!(data);
    });

    socket.on('round_finished', (data) {
      if (onRoundFinished != null) onRoundFinished!(data);
    });

    socket.on('queue_updated', (data) {
      if (onQueueUpdated != null) onQueueUpdated!(data);
    });

    socket.on('buzz_reset', (_) {
      if (onBuzzReset != null) onBuzzReset!();
    });
  }

  // Socket Actions
  void joinRoom(String roomCode, String nickname) {
    socket.emit('join_room', {
      'roomCode': roomCode, 
      'nickname': nickname
    });
  }

  void buzz(String roomCode) {
    socket.emit('buzz', {'roomCode': roomCode});
  }

  void judgeAnswer(String roomCode, bool isCorrect, int points) {
    socket.emit('judge_answer', {
      'roomCode': roomCode,
      'isCorrect': isCorrect,
      'points': points,
    });
  }

  void resetBuzz(String roomCode) {
    socket.emit('reset_buzz', {'roomCode': roomCode});
  }

  void dispose() {
    socket.dispose();
  }
}