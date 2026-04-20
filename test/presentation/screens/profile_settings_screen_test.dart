// ABOUTME: Widget tests for ProfileSettingsScreen — unified allergen and settings destination.
// ABOUTME: Verifies section rendering and Ponovi uvod service call.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udahni/core/services/external_actions.dart';
import 'package:udahni/core/services/onboarding_service.dart';
import 'package:udahni/presentation/screens/profile_settings_screen.dart';
import 'package:udahni/presentation/widgets/hint_card.dart';
import 'package:udahni/presentation/viewmodels/home_view_model.dart';
import 'package:udahni/presentation/viewmodels/personal_allergen_view_model.dart';

import '../../helpers/fake_external_actions.dart';
import '../../helpers/fake_onboarding_service.dart';
import '../../helpers/fake_pollen_repository.dart';

Widget _buildTestApp(
  OnboardingService service, {
  ExternalActions? externalActions,
}) {
  SharedPreferences.setMockInitialValues({});
  final repo = FakePollenRepository();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => HomeViewModel(pollenRepository: repo)),
      ChangeNotifierProvider(create: (_) => PersonalAllergenViewModel()),
      Provider<OnboardingService>.value(value: service),
      Provider<ExternalActions>.value(
        value: externalActions ?? FakeExternalActions(),
      ),
    ],
    child: MaterialApp(
      routes: {
        '/': (_) => const ProfileSettingsScreen(),
        '/onboarding': (_) => const Scaffold(body: Text('onboarding')),
      },
      initialRoute: '/',
    ),
  );
}

void main() {
  group('ProfileSettingsScreen', () {
    testWidgets('renders allergen section', (tester) async {
      await tester.pumpWidget(_buildTestApp(FakeOnboardingService()));
      await tester.pump();

      expect(find.text('Moji alergeni'), findsOneWidget);
    });

    testWidgets('renders settings section with Ponovi uvod', (tester) async {
      await tester.pumpWidget(_buildTestApp(FakeOnboardingService()));
      await tester.pump();

      expect(find.text('Podešavanja'), findsOneWidget);
      expect(find.text('Ponovi uvod'), findsOneWidget);
    });

    testWidgets('tapping Ponovi uvod calls resetOnboarding', (tester) async {
      final service = FakeOnboardingService();
      await tester.pumpWidget(_buildTestApp(service));
      await tester.pump();

      await tester.tap(find.text('Ponovi uvod'));
      await tester.pumpAndSettle();

      expect(service.resetCalled, isTrue);
      expect(find.text('onboarding'), findsOneWidget);
    });

    testWidgets('shows hint card on first visit', (tester) async {
      await tester.pumpWidget(_buildTestApp(FakeOnboardingService()));
      await tester.pumpAndSettle(); // let post-frame callback run

      expect(find.byType(HintCard), findsOneWidget);
    });

    testWidgets('tapping Oceni aplikaciju requests app review', (tester) async {
      final actions = FakeExternalActions();
      await tester.pumpWidget(
        _buildTestApp(FakeOnboardingService(), externalActions: actions),
      );
      await tester.pump();

      await tester.tap(find.text('Oceni aplikaciju'));
      await tester.pump();

      expect(actions.requestAppReviewCallCount, equals(1));
    });

    testWidgets('tapping Politika privatnosti opens privacy policy', (tester) async {
      final actions = FakeExternalActions();
      await tester.pumpWidget(
        _buildTestApp(FakeOnboardingService(), externalActions: actions),
      );
      await tester.pump();

      await tester.tap(find.text('Politika privatnosti'));
      await tester.pump();

      expect(actions.openPrivacyPolicyCallCount, equals(1));
    });

    testWidgets('dismissing hint calls markScreenVisited and hides card', (tester) async {
      final service = FakeOnboardingService();
      await tester.pumpWidget(_buildTestApp(service));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(service.markScreenVisitedCalled, isTrue);
      expect(service.lastMarkScreenVisitedKey, equals(OnboardingService.allergensKey));
      expect(find.byType(HintCard), findsNothing);
    });
  });
}
