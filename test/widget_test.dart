// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeopardy_app/main.dart';
import 'package:jeopardy_app/screens/home_screen.dart';
// import 'package:jeopardy_app/screens/game_room_screen.dart';
// import 'package:jeopardy_app/widgets/score_board.dart';
import 'package:jeopardy_app/widgets/jeopardy_grid.dart';
import 'package:jeopardy_app/widgets/question_card.dart';

void main() {
  testWidgets('Home Screen Load Test', (WidgetTester tester) async {
    // Set a large screen size to ensure layout fits
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // 1. Verify we are on the Home Screen
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('JEOPARTY'), findsOneWidget);
    
    // 2. Verify Buttons exist
    expect(find.text('CRIAR SALA'), findsOneWidget);
    expect(find.text('SAIR'), findsOneWidget);
    
    // 3. Tap "CRIAR SALA"
    await tester.tap(find.text('CRIAR SALA'));
    await tester.pumpAndSettle();
    
    // 4. Verify we navigated to Game Room (Grid)
    expect(find.byType(JeopardyGrid), findsOneWidget);
  });
}

