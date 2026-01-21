import 'package:flutter/material.dart';
import '../widgets/score_board.dart';
import '../widgets/jeopardy_grid.dart';

class GameRoomScreen extends StatelessWidget {
  const GameRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.transparent, // Handled by theme now
      body: Row(
        children: const [
          // Left Side: Score Column (as requested by user, overriding image that has it on right)
          ScoreBoard(),
          
          // Main Content: Categories and Questions
          JeopardyGrid(),
        ],
      ),
    );
  }
}
