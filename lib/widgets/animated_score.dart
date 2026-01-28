import 'package:flutter/material.dart';

class AnimatedScore extends StatelessWidget {
  final int score;
  final TextStyle? style;
  final Duration duration;
  final String prefix;

  const AnimatedScore({
    super.key,
    required this.score,
    this.style,
    this.duration = const Duration(milliseconds: 500),
    this.prefix = '\$',
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: score),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Text(
          '$prefix$value',
          textAlign: TextAlign.center,
          style: style,
        );
      },
    );
  }
}
