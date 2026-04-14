// ABOUTME: Widget tests for OnboardingScreen — intro cards shown on first launch.
// ABOUTME: Verifies pagination, skip/start behavior, and service calls.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:udahni/core/services/onboarding_service.dart';
import 'package:udahni/presentation/screens/onboarding_screen.dart';

import '../../helpers/fake_onboarding_service.dart';

Widget _buildTestApp(OnboardingService service) {
  return Provider<OnboardingService>.value(
    value: service,
    child: MaterialApp(
      initialRoute: '/onboarding',
      routes: {
        '/onboarding': (_) => const OnboardingScreen(),
        '/': (_) => const Scaffold(body: Text('main')),
      },
    ),
  );
}

void main() {
  group('OnboardingScreen', () {
    testWidgets('renders first card on load', (tester) async {
      await tester.pumpWidget(_buildTestApp(FakeOnboardingService()));
      await tester.pump();

      // First card title should be visible
      expect(find.text('Dobrodošli'), findsOneWidget);
    });

    testWidgets('Dalje advances to next card', (tester) async {
      await tester.pumpWidget(_buildTestApp(FakeOnboardingService()));
      await tester.pump();

      await tester.tap(find.text('Dalje'));
      await tester.pumpAndSettle();

      // Second card should now be visible; first card title gone
      expect(find.text('Dobrodošli'), findsNothing);
    });

    testWidgets('last card shows Počni instead of Dalje', (tester) async {
      await tester.pumpWidget(_buildTestApp(FakeOnboardingService()));
      await tester.pump();

      // Advance through all 4 cards (3 taps to reach last card)
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Dalje'));
        await tester.pumpAndSettle();
      }

      expect(find.text('Počni'), findsOneWidget);
      expect(find.text('Dalje'), findsNothing);
    });

    testWidgets('Preskoči calls markOnboardingComplete', (tester) async {
      final service = FakeOnboardingService();
      await tester.pumpWidget(_buildTestApp(service));
      await tester.pump();

      await tester.tap(find.text('Preskoči'));
      await tester.pumpAndSettle();

      expect(service.completeCalled, isTrue);
      expect(find.text('main'), findsOneWidget);
    });

    testWidgets('Počni calls markOnboardingComplete', (tester) async {
      final service = FakeOnboardingService();
      await tester.pumpWidget(_buildTestApp(service));
      await tester.pump();

      // Advance to last card
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Dalje'));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Počni'));
      await tester.pumpAndSettle();

      expect(service.completeCalled, isTrue);
      expect(find.text('main'), findsOneWidget);
    });
  });
}
