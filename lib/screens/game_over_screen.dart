import 'package:flutter/material.dart';

class GameOverScreen extends StatelessWidget {
  final List<dynamic> leaderboard;

  const GameOverScreen({super.key, required this.leaderboard});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[900],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "FIM DE JOGO",
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 4)],
              ),
            ),
            const SizedBox(height: 48),
            Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD700), width: 2),
              ),
              child: Column(
                children: leaderboard.map((player) {
                  final rank = player['rank'];
                  final isWinner = rank == 1;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            if (isWinner) const Text("👑 ", style: TextStyle(fontSize: 32)),
                            Text(
                              "#$rank ${player['nickname']}",
                              style: TextStyle(
                                color: isWinner ? const Color(0xFFFFD700) : Colors.white,
                                fontSize: isWinner ? 32 : 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "\$${player['score']}",
                          style: TextStyle(
                            color: isWinner ? const Color(0xFFFFD700) : Colors.white70,
                            fontSize: isWinner ? 32 : 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              ),
              child: const Text("VOLTAR AO MENU", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
