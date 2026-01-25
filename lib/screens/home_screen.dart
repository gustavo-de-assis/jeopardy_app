import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import 'game_room_screen.dart';
import 'category_selection_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GameSocketService _socketService = GameSocketService();
  bool _isHostAuthenticated = false;
  String? _pairingCode;
  String? _authenticatedHostId;

  @override
  void initState() {
    super.initState();
    _socketService.initConnection();
    if (kIsWeb) {
      _initWebPairing();
    } else {
      _initMobileListeners();
    }
  }

  void _initWebPairing() {
    _socketService.requestPairing(onCodeReceived: (code) {
      if (mounted) {
        setState(() => _pairingCode = code);
      }
    });

    _socketService.onHostAuthenticated = (userId) {
      if (mounted) {
        setState(() {
          _isHostAuthenticated = true;
          _authenticatedHostId = userId;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Host autenticado!"), backgroundColor: Colors.green),
        );
      }
    };
  }

  void _initMobileListeners() {
    _socketService.onJoinRoomAsHost = (roomCode) {
      if (mounted) {
        // Automatically join the room created on web
        Navigator.of(context).pushNamed(
          '/lobby',
          arguments: {
            'isHost': true,
            'roomCode': roomCode,
            'userId': _authenticatedHostId,
          }
        );
      }
    };
  }

  Future<void> _createRoom(BuildContext context, WidgetRef ref) async {
    if (!_isHostAuthenticated && kIsWeb) return;

    try {
      final hostId = _authenticatedHostId ?? "host_user_123";
      final result = await ref.read(apiServiceProvider).createSession(hostId);
      final sessionId = result['_id']; 
      final roomCode = result['roomCode'];
      
      if (mounted) {
        // Notify gateway about room creation to sync mobile
        _socketService.notifyRoomCreated(roomCode);

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CategorySelectionScreen(
              sessionId: sessionId,
              userId: hostId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao criar sala: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _exitApp() {
    SystemNavigator.pop();
  }

  void _showLoginDialog() {
    final nickController = TextEditingController();
    final passController = TextEditingController();
    final pairingController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("LOGIN DO HOST"),
        backgroundColor: Colors.blue[900],
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nickController,
              decoration: const InputDecoration(labelText: "NICKNAME"),
              style: const TextStyle(color: Colors.white),
            ),
            TextField(
              controller: passController,
              decoration: const InputDecoration(labelText: "PASSWORD"),
              obscureText: true,
              style: const TextStyle(color: Colors.white),
            ),
            const Divider(color: Colors.white24, height: 32),
            TextField(
              controller: pairingController,
              decoration: const InputDecoration(labelText: "CÓDIGO DE PAREAMENTO WEB (OPCIONAL)"),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR", style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              final nick = nickController.text.trim();
              final pass = passController.text.trim();
              final pairing = pairingController.text.trim().toUpperCase();

              if (nick.isEmpty || pass.isEmpty) return;

              _socketService.login(nick, pass, onResponse: (data) {
                if (data['success'] == true) {
                  final userId = data['userId'];
                  if (pairing.isNotEmpty) {
                    _socketService.authenticateWeb(pairing, userId);
                  }
                  if (mounted) {
                    Navigator.pop(context);
                    setState(() {
                      _isHostAuthenticated = true;
                      _authenticatedHostId = userId;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Logado com sucesso!"), backgroundColor: Colors.green),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(data['message'] ?? "Erro de login"), backgroundColor: Colors.red),
                    );
                  }
                }
              });
            },
            child: const Text("LOGIN"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTitle(),
            const SizedBox(height: 80),
            
            if (kIsWeb) ...[
              if (_pairingCode != null && !_isHostAuthenticated)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Text(
                    "CÓDIGO DE PAREAMENTO: $_pairingCode",
                    style: const TextStyle(fontSize: 24, color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
                  ),
                ),
              _buildMenuButton(
                label: "CRIAR SALA",
                onPressed: _isHostAuthenticated ? () => _createRoom(context, ref) : null,
              ),
              if (!_isHostAuthenticated)
                 const Padding(
                   padding: EdgeInsets.only(top: 16.0),
                   child: Text("Faca login no mobile para habilitar", style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic)),
                 ),
              const SizedBox(height: 24),
              _buildMenuButton(
                label: "SAIR",
                onPressed: _exitApp,
              ),
            ] else ...[
              if (!_isHostAuthenticated)
                _buildMenuButton(
                  label: "LOGIN HOST",
                  onPressed: _showLoginDialog,
                )
              else 
                const Text("LOGADO COMO HOST", style: TextStyle(color: Color(0xFFFFD700), fontSize: 24, fontWeight: FontWeight.bold)),
              
              const SizedBox(height: 24),
              _buildMenuButton(
                label: "ENTRAR NA PARTIDA",
                onPressed: () {
                  Navigator.of(context).pushNamed('/lobby', arguments: {'isHost': false});
                },
              ),
              const SizedBox(height: 24),
              _buildMenuButton(
                label: "SAIR",
                onPressed: _exitApp,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          colors: [
            Color(0xFFE0E0E0), Color(0xFFB0B0B0), Color(0xFFFFFFFF), Color(0xFF90A4AE), Color(0xFFE0E0E0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          tileMode: TileMode.mirror,
        ).createShader(bounds);
      },
      child: Text(
        'JEOPARTY',
        style: TextStyle(
          fontFamily: 'gyparody',
          fontSize: kIsWeb ? 120 : 64,
          fontWeight: FontWeight.normal,
          color: Colors.white,
          shadows: const [
            Shadow(color: Colors.black54, offset: Offset(4, 4), blurRadius: 8),
            Shadow(color: Colors.black26, offset: Offset(6, 6), blurRadius: 12),
          ],
          letterSpacing: 4.0,
        ),
      ),
    );
  }

  Widget _buildMenuButton({required String label, required VoidCallback? onPressed}) {
    final double buttonWidth = kIsWeb ? 300 : 250;
    final double buttonHeight = kIsWeb ? 60 : 50;
    final double fontSize = kIsWeb ? 24 : 18;

    return SizedBox(
      width: buttonWidth,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade900,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade800,
          disabledForegroundColor: Colors.white24,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.white30, width: 2),
          ),
          elevation: 8,
          shadowColor: Colors.black54,
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
      ),
    );
  }
}
