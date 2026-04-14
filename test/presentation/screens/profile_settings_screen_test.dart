// ABOUTME: Widget tests for ProfileSettingsScreen — unified allergen and settings destination.
// ABOUTME: Verifies section rendering and Ponovi uvod service call.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udahni/core/services/onboarding_service.dart';
import 'package:udahni/presentation/screens/profile_settings_screen.dart';
import 'package:udahni/presentation/viewmodels/home_view_model.dart';
import 'package:udahni/presentation/viewmodels/personal_allergen_view_model.dart';

import '../../helpers/fake_onboarding_service.dart';
import '../../helpers/fake_pollen_repository.dart';

Widget _buildTestApp(OnboardingService service) {
  SharedPreferences.setMockInitialValues({});
  final repo = FakePollenRepository();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => HomeViewModel(pollenRepository: repo)),
      ChangeNotifierProvider(create: (_) => PersonalAllergenViewModel()),
      Provider<OnboardingService>.value(value: service),
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
      await tester.pump();

      expect(service.resetCalled, isTrue);
    });
  });
}
