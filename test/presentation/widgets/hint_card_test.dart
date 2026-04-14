// ABOUTME: Tests for HintCard widget — dismissible contextual hint shown on first screen visit.
// ABOUTME: Verifies message rendering and dismiss callback.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udahni/presentation/widgets/hint_card.dart';

void main() {
  group('HintCard', () {
    testWidgets('renders message text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HintCard(
              message: 'Tap a station marker for details',
              onDismiss: () {},
            ),
          ),
        ),
      );

      expect(find.text('Tap a station marker for details'), findsOneWidget);
    });

    testWidgets('tapping × calls onDismiss', (tester) async {
      var dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HintCard(
              message: 'Some hint',
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      expect(dismissed, isTrue);
    });
  });
}
