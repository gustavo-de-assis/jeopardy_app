import 'package:flutter/material.dart';
import '../services/socket_service.dart';

class GameOverScreen extends StatelessWidget {
  final List<dynamic> leaderboard;
  final bool isHost;
  final bool isMobile;
  final String roomCode;
  final String? userId;

  const GameOverScreen({
    super.key,
    required this.leaderboard,
    required this.isHost,
    this.isMobile = false,
    required this.roomCode,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final top3 = leaderboard.take(3).toList();
    final theRest = leaderboard.length > 3 ? leaderboard.sublist(3) : [];

    return Scaffold(
      backgroundColor: const Color(0xFF000033),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF000044), Color(0xFF000011)],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 60),
            const Text(
              "FIM DE JOGO!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 64,
                fontWeight: FontWeight.bold,
                fontFamily: 'itc-korinna',
                shadows: [Shadow(color: Colors.amber, blurRadius: 20)],
              ),
            ),
            const SizedBox(height: 40),
            if (isMobile && !isHost)
               _buildPersonalizedFeedback(context)
            else
              // Podium
              _buildPodium(top3),
            const SizedBox(height: 40),
            // Additional players
            if (theRest.isNotEmpty)
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: ListView.builder(
                    itemCount: theRest.length,
                    itemBuilder: (context, index) {
                      final p = theRest[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.white10,
                          child: Text("${index + 4}", style: const TextStyle(color: Colors.white70)),
                        ),
                        title: Text(p['nickname'], style: const TextStyle(color: Colors.white, fontSize: 20)),
                        trailing: Text("\$${p['score']}", style: const TextStyle(color: Colors.white70, fontSize: 20)),
                      );
                    },
                  ),
                ),
              )
            else
              const Spacer(),
            
            // Host Controls
            if (isHost)
              Padding(
                padding: const EdgeInsets.all(40.0),
                child: ElevatedButton(
                  onPressed: () {
                    GameSocketService().resetRoom(roomCode);
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text("REINICIAR SALA", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(40.0),
                child: TextButton(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  child: const Text("SAIR", style: TextStyle(color: Colors.white54, fontSize: 18)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodium(List<dynamic> top3) {
    if (top3.isEmpty) return const SizedBox();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd Place
        if (top3.length > 1) _buildPodiumStep(top3[1], 160, const Color(0xFFC0C0C0), "2nd"),
        const SizedBox(width: 20),
        // 1st Place
        _buildPodiumStep(top3[0], 220, const Color(0xFFFFD700), "1st", hasCrown: true),
        const SizedBox(width: 20),
        // 3rd Place
        if (top3.length > 2) _buildPodiumStep(top3[2], 120, const Color(0xFFCD7F32), "3rd"),
      ],
    );
  }

  Widget _buildPodiumStep(dynamic player, double height, Color color, String rankLabel, {bool hasCrown = false}) {
    return Column(
      children: [
        if (hasCrown) 
          const Icon(Icons.workspace_premium, color: Colors.amber, size: 48),
        Text(
          player['nickname'], 
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
        ),
        Text(
          "\$${player['score']}", 
          style: TextStyle(color: color.withOpacity(0.8), fontSize: 20, fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 10),
        Container(
          width: 140,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color, color.withAlpha(100)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)],
          ),
          child: Center(
            child: Text(
              rankLabel, 
              style: const TextStyle(color: Colors.black45, fontSize: 32, fontWeight: FontWeight.w900)
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalizedFeedback(BuildContext context) {
    // Find my rank
    final int myIndex = leaderboard.indexWhere((p) => p['id'] == userId || p['socketId'] == userId);
    final int rank = myIndex + 1;
    final bool isWinner = rank == 1;
    final player = myIndex != -1 ? leaderboard[myIndex] : null;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isWinner ? Icons.workspace_premium : Icons.sentiment_very_satisfied,
            color: isWinner ? Colors.amber : Colors.white54,
            size: 100,
          ),
          const SizedBox(height: 24),
          Text(
            isWinner ? "PARABÉNS, VENCEDOR!" : "MAIS SORTE NA PRÓXIMA!",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isWinner ? Colors.amber : Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontFamily: 'itc-korinna',
            ),
          ),
          const SizedBox(height: 16),
          if (player != null) ...[
            Text(
              "Sua Pontuação: \$${player['score']}",
              style: const TextStyle(color: Colors.white70, fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              "Sua Posição: $rankº lugar",
              style: const TextStyle(color: Colors.white54, fontSize: 18),
            ),
          ],
        ],
      ),
    );
  }
}
