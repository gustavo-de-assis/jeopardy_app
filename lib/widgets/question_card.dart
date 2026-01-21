import 'package:flutter/material.dart';

class QuestionCard extends StatelessWidget {
  final int amount;
  final bool isAnswered;
  final VoidCallback onTap;

  const QuestionCard({
    super.key,
    required this.amount,
    required this.isAnswered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Material(
          color: Colors.blue[900], // Dark blue base
          borderRadius: BorderRadius.circular(8),
          elevation: 4,
          child: InkWell(
            onTap: isAnswered ? null : onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade800,
                    Colors.blue.shade900,
                  ],
                ),
                border: Border.all(color: Colors.black54, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    offset: Offset(2, 2),
                    blurRadius: 2,
                  )
                ],
              ),
              child: Center(
                child: Text(
                  '\$$amount',
                  style: TextStyle(
                    color: isAnswered 
                        ? const Color(0xFF8B8000) // Dark Gold for answered
                        : const Color(0xFFFFD700), // Gold for active
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(isAnswered ? 0.3 : 1.0),
                        offset: const Offset(2, 2),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
