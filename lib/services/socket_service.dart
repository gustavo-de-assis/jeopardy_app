import 'dart:io';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';

class GameSocketService {
  // Singleton pattern
  static final GameSocketService _instance = GameSocketService._internal();
  factory GameSocketService() => _instance;
  GameSocketService._internal();

  IO.Socket? socket;
  
  // Callbacks for UI updates
  Function(Map<String, dynamic>)? onPlayerJoined;
  Function(Map<String, dynamic>)? onPlayerAnswering;
  Function(Map<String, dynamic>)? onRoundFinished;
  Function(Map<String, dynamic>)? onQueueUpdated;
  Function()? onBuzzReset;
  Function()? onGameStarted;
  Function(Map<String, dynamic>)? onQuestionOpened;
  Function(String)? onPairingCodeReceived;
  Function(String)? onHostAuthenticated;
  Function(String)? onJoinRoomAsHost;
  // Final Jeopardy Callbacks
  Function(Map<String, dynamic>)? onFinalPhaseStarted;
  Function(Map<String, dynamic>)? onWagerConfirmed;
  Function()? onAllWagersPlaced;
  Function(Map<String, dynamic>)? onShowFinalQuestion;
  Function()? onJudgingPhaseStarted;
  Function(Map<String, dynamic>)? onAnswerRevealedOnBoard;
  Function(Map<String, dynamic>)? onGameOver;

  void initConnection() {
    if (socket != null) {
      if (!socket!.connected) {
         socket!.connect();
      }
      return;
    }

    // Current machine IP from previous investigation
    // const String baseUrl = 'http://192.168.1.67:3000';
    String baseUrl;

if (kIsWeb) {
  baseUrl = 'http://127.0.0.1:3000'; // Web no mesmo PC
} else if (Platform.isAndroid) {
  baseUrl = 'http://10.0.2.2:3000'; // Emulador Android (Endereço Mágico)
  // Se for celular FÍSICO, use o IP da sua rede: 'http://192.168.1.XX:3000'
} else {
  baseUrl = 'http://localhost:3000'; // iOS Simulator
}
    debugPrint("GameSocketService: Connecting to $baseUrl");
    socket = IO.io(baseUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect() 
        .build());

    socket!.connect();
    _setupListeners();
  }

  void _setupListeners() {
    if (socket == null) return;

    socket!.onConnect((_) {
      debugPrint('Conectado ao Backend: ${socket!.id}');
    });

    socket!.onConnectError((data) => debugPrint('Erro de Conexão Socket: $data'));
    socket!.onError((data) => debugPrint('Erro Socket: $data'));

    socket!.onDisconnect((_) => debugPrint('Desconectado do Backend'));

    socket!.on('player_joined', (data) {
      if (onPlayerJoined != null) onPlayerJoined!(data);
    });
    
    socket!.on('player_answering', (data) {
      if (onPlayerAnswering != null) onPlayerAnswering!(data);
    });

    socket!.on('round_finished', (data) {
      if (onRoundFinished != null) onRoundFinished!(data);
    });

    socket!.on('queue_updated', (data) {
      if (onQueueUpdated != null) onQueueUpdated!(data);
    });

    socket!.on('buzz_reset', (_) {
      if (onBuzzReset != null) onBuzzReset!();
    });

    socket!.on('game_started', (_) {
      if (onGameStarted != null) onGameStarted!();
    });

    socket!.on('question_opened', (data) {
      if (onQuestionOpened != null) onQuestionOpened!(data);
    });

    socket!.on('host_authenticated', (data) {
      if (onHostAuthenticated != null) onHostAuthenticated!(data['userId']);
    });

    socket!.on('join_room_as_host', (data) {
      if (onJoinRoomAsHost != null) onJoinRoomAsHost!(data['roomCode']);
    });

    // Final Jeopardy Listeners
    socket!.on('final_phase_started', (data) {
      if (onFinalPhaseStarted != null) onFinalPhaseStarted!(data);
    });
    socket!.on('wager_confirmed', (data) {
      if (onWagerConfirmed != null) onWagerConfirmed!(data);
    });
    socket!.on('all_wagers_placed', (_) {
      if (onAllWagersPlaced != null) onAllWagersPlaced!();
    });
    socket!.on('show_final_question', (data) {
      if (onShowFinalQuestion != null) onShowFinalQuestion!(data);
    });
    socket!.on('judging_phase_started', (_) {
      if (onJudgingPhaseStarted != null) onJudgingPhaseStarted!();
    });
    socket!.on('answer_revealed_on_board', (data) {
      if (onAnswerRevealedOnBoard != null) onAnswerRevealedOnBoard!(data);
    });
    socket!.on('game_over', (data) {
      if (onGameOver != null) onGameOver!(data);
    });
  }

  // Socket Actions
  void joinRoom(String roomCode, String nickname, {String? userId, Function(Map<String, dynamic>)? onResponse}) {
    if (socket == null) initConnection();
    socket!.emitWithAck('join_room', {
      'roomCode': roomCode, 
      'nickname': nickname,
      'userId': userId,
    }, ack: (data) {
      if (onResponse != null) onResponse(data);
    });
  }

  void startGame(String roomCode) {
    if (socket == null) initConnection();
    socket!.emit('start_game', {'roomCode': roomCode});
  }

  void openQuestion(String roomCode, Map<String, dynamic> questionData) {
    if (socket == null) initConnection();
    socket!.emit('open_question', {
      'roomCode': roomCode,
      'question': questionData,
    });
  }

  void buzz(String roomCode) {
    if (socket == null) initConnection();
    socket!.emit('buzz', {'roomCode': roomCode});
  }

  void judgeAnswer(String roomCode, bool isCorrect, int points) {
    if (socket == null) initConnection();
    socket!.emit('judge_answer', {
      'roomCode': roomCode,
      'isCorrect': isCorrect,
      'points': points,
    });
  }

  void resetBuzz(String roomCode) {
    if (socket == null) initConnection();
    socket!.emit('reset_buzz', {'roomCode': roomCode});
  }

  void requestPairing({required Function(String) onCodeReceived}) {
    if (socket == null) initConnection();
    socket!.emitWithAck('request_pairing', {}, ack: (data) {
      final code = data['code'] as String;
      onCodeReceived(code);
    });
  }

  void authenticateWeb(String code, String userId) {
    if (socket == null) initConnection();
    socket!.emit('authenticate_web', {'code': code, 'userId': userId});
  }

  void notifyRoomCreated(String roomCode) {
    if (socket == null) initConnection();
    socket!.emit('room_created', {'roomCode': roomCode});
  }

  void login(String nickname, String password, {required Function(Map<String, dynamic>) onResponse}) {
    if (socket == null) initConnection();
    socket!.emitWithAck('login', {
      'nickname': nickname,
      'password': password,
    }, ack: (data) {
      onResponse(Map<String, dynamic>.from(data));
    });
  }

  // Final Jeopardy Actions
  void startFinalJeopardy(String roomCode) {
    if (socket == null) initConnection();
    socket!.emit('start_final_jeopardy', {'roomCode': roomCode});
  }

  void submitWager(String roomCode, int amount) {
     if (socket == null) initConnection();
    socket!.emit('submit_wager', {'roomCode': roomCode, 'amount': amount});
  }

  void revealFinalQuestion(String roomCode) {
     if (socket == null) initConnection();
    socket!.emit('reveal_final_question', {'roomCode': roomCode});
  }

  void submitFinalAnswer(String roomCode, String text) {
     if (socket == null) initConnection();
    socket!.emit('submit_final_answer', {'roomCode': roomCode, 'text': text});
  }

  void startJudging(String roomCode) {
     if (socket == null) initConnection();
    socket!.emit('start_judging', {'roomCode': roomCode});
  }

  void revealAnswerToRoom(String roomCode, String playerId) {
     if (socket == null) initConnection();
    socket!.emit('reveal_answer_to_room', {'roomCode': roomCode, 'playerId': playerId});
  }

  void resolveApproximationWinner(String roomCode, String winnerPlayerId) {
     if (socket == null) initConnection();
    socket!.emit('resolve_approximation_winner', {'roomCode': roomCode, 'winnerPlayerId': winnerPlayerId});
  }

  void resolveStandardRound(String roomCode, List<Map<String, dynamic>> results) {
     if (socket == null) initConnection();
    socket!.emit('resolve_standard_round', {'roomCode': roomCode, 'results': results});
  }

  void dispose() {
    socket?.dispose();
    socket = null;
  }
}