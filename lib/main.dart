import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/connection_screen.dart';
import 'screens/scan_server_screen.dart';
import 'screens/home_screen.dart';
import 'screens/lobby_screen.dart';
import 'screens/game_room_screen.dart';
import 'screens/mobile_game_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jeoparty',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
      ),
      builder: (context, child) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0xff02227A),
                Color(0xff2C62E8),
                Color(0xff3C67E6),
                Color(0xff2C62E8),
                Color(0xff02227A),
              ],
              tileMode: TileMode.mirror,
            ),
          ),
          child: child,
        );
      },
      routes: {
        '/': (context) => const HomeScreen(),
        '/setup': (context) => kIsWeb ? const ConnectionScreen() : const ScanServerScreen(),
        '/lobby': (context) => const LobbyScreen(),
        '/game': (context) => const GameRoomScreen(),
        '/mobile-game': (context) => const MobileGameScreen(),
      },
      initialRoute: '/setup',
    );
  }
}
