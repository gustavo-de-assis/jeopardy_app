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
import 'package:jeopardy_app/widgets/question_card.dart';

void main() {
  testWidgets('Full Jeopardy Game Flow Test', (WidgetTester tester) async {
    // Set a large screen size to ensure layout fits
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // 1. Verify we are on the grid
    expect(find.byType(JeopardyGrid), findsOneWidget);
    
    // 2. Answer all 25 questions
    final cards = find.byType(QuestionCard);
    expect(cards, findsNWidgets(25));
    
    for (int i = 0; i < 25; i++) {
        await tester.tap(cards.at(i));
        await tester.pump(); 
        
        // Wait for question view
        expect(find.byKey(const Key('question_view')), findsOneWidget);
        
        // Tap to close
        await tester.tap(find.byKey(const Key('question_view')));
        await tester.pump();
        
        // Wait for grid
        expect(find.byKey(const Key('question_view')), findsNothing);
    }

    // 3. Verify Bonus Button appears
    final bonusFinder = find.text('BONUS');
    expect(bonusFinder, findsOneWidget);
    await tester.ensureVisible(bonusFinder);

    // 4. Tap Bonus
    await tester.tap(bonusFinder);
    await tester.pump(); // Rebuild with new state
    
    // 5. Verify Intro "PERGUNTA FINAL"
    expect(find.text('PERGUNTA FINAL'), findsOneWidget);
    
    // 6. Wait 5 seconds
    await tester.pump(const Duration(seconds: 5));
    
    // 7. Verify Question & Timer
    expect(find.text('Final Question Placeholder Text'), findsOneWidget);
    expect(find.text('30'), findsOneWidget); // Timer start
    
    // 8. Wait 15 seconds
    await tester.pump(const Duration(seconds: 15));
    expect(find.text('15'), findsOneWidget);
    
    // 9. Wait remaining 15s
    await tester.pump(const Duration(seconds: 15));
    
    // 10. Verify Timeout "Acabou o tempo"
    expect(find.text('Acabou o tempo'), findsOneWidget);
    
    // 11. Tap to close
    await tester.tap(find.text('Acabou o tempo'));
    await tester.pumpAndSettle();
    
    // 12. Back to grid
    expect(find.byType(JeopardyGrid), findsOneWidget);
  });
}
