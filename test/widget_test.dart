// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeopardy_app/main.dart';
import 'package:jeopardy_app/screens/game_room_screen.dart';
import 'package:jeopardy_app/widgets/score_board.dart';
import 'package:jeopardy_app/widgets/jeopardy_grid.dart';

void main() {
  testWidgets('GameRoomScreen loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that GameRoomScreen is present
    expect(find.byType(GameRoomScreen), findsOneWidget);
    
    // Verify that ScoreBoard is present
    expect(find.byType(ScoreBoard), findsOneWidget);

    // Verify that JeopardyGrid is present
    expect(find.byType(JeopardyGrid), findsOneWidget);

    // Verify standard text is present
    expect(find.text('Team #1'), findsOneWidget);
    expect(find.text('CATEGORY 1'), findsOneWidget);
  });
}
