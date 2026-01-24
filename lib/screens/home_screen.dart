import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'game_room_screen.dart';
import 'category_selection_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _createRoom(BuildContext context, WidgetRef ref) async {
    try {
      // For now, using a hardcoded hostId or just a dummy one since we don't have full auth yet
      final result = await ref.read(apiServiceProvider).createSession("host_user_123");
      final sessionId = result['_id']; // MongoDB ID
      
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CategorySelectionScreen(sessionId: sessionId),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao criar sala: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _navigateToGame(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GameRoomScreen(),
      ),
    );
  }

  void _exitApp() {
    SystemNavigator.pop();
  }

  Future<void> _testApi(BuildContext context, WidgetRef ref) async {
    try {
      final resultCat = await ref.read(apiServiceProvider).seedCategories();
      final resultQuest = await ref.read(apiServiceProvider).seedQuestions();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Cat: $resultCat, Quest: $resultQuest")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Let global gradient show
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Title
            ShaderMask(
              shaderCallback: (bounds) {
                return const LinearGradient(
                  colors: [
                    Color(0xFFE0E0E0), // Light Silver
                    Color(0xFFB0B0B0), // Silver
                    Color(0xFFFFFFFF), // White highlight
                    Color(0xFF90A4AE), // Blue-ish Gray
                    Color(0xFFE0E0E0), // Light Silver
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  tileMode: TileMode.mirror,
                ).createShader(bounds);
              },
              child: const Text(
                'JEOPARTY',
                style: TextStyle(
                  fontSize: 96,
                  fontWeight: FontWeight.w900,
                  color: Colors.white, // Required for ShaderMask to work (as mask)
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      offset: Offset(4, 4),
                      blurRadius: 8,
                    ),
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(6, 6),
                      blurRadius: 12,
                    ),
                  ],
                  letterSpacing: 4.0,
                ),
              ),
            ),
            
            const SizedBox(height: 80),

            // Buttons
            _buildMenuButton(
              label: "CRIAR SALA",
              onPressed: () => _createRoom(context, ref),
            ),
            const SizedBox(height: 24),
            _buildMenuButton(
              label: "TESTAR API (SEED)",
              onPressed: () => _testApi(context, ref),
            ),
            const SizedBox(height: 24),
            _buildMenuButton(
              label: "ENTRAR EM SALA",
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
        ),
      ),
    );
  }

  Widget _buildMenuButton({required String label, required VoidCallback onPressed}) {
    return SizedBox(
      width: 300,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade900,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.white30, width: 2),
          ),
          elevation: 8,
          shadowColor: Colors.black54,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
