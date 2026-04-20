// ABOUTME: App entry point with provider setup and theme configuration.
// ABOUTME: Registers repositories and view models, then launches the main screen.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:udahni/core/services/external_actions.dart';
import 'package:udahni/core/services/onboarding_service.dart';
import 'package:udahni/core/theme/app_theme.dart';
import 'package:udahni/data/repositories/pollen_repository.dart';
import 'package:udahni/presentation/screens/main_screen.dart';
import 'package:udahni/presentation/screens/onboarding_screen.dart';
import 'package:udahni/presentation/viewmodels/home_view_model.dart';
import 'package:udahni/presentation/viewmodels/map_view_model.dart';
import 'package:udahni/presentation/viewmodels/personal_allergen_view_model.dart';

//--------------------------------------------------------------------------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final onboardingService = OnboardingService();
  final showOnboarding = !await onboardingService.isOnboardingComplete();
  final pollenRepository = PollenRepository();

  runApp(
    MultiProvider(
      providers: [
        Provider<OnboardingService>.value(value: onboardingService),
        Provider<ExternalActions>(create: (_) => const PlatformExternalActions()),
        Provider<PollenRepository>(
          create: (_) => pollenRepository,
          dispose: (_, repo) => repo.dispose(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              HomeViewModel(pollenRepository: pollenRepository)
                ..loadInitialData(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              MapViewModel(pollenRepository: pollenRepository)..loadLocations(),
        ),
        ChangeNotifierProvider(
          create: (_) => PersonalAllergenViewModel()..loadSelections(),
        ),
      ],
      child: AllergenApp(showOnboarding: showOnboarding),
    ),
  );
}

//--------------------------------------------------------------------------
class AllergenApp extends StatelessWidget {
  final bool showOnboarding;

  const AllergenApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Udahni',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: showOnboarding ? '/onboarding' : '/',
      routes: {
        '/': (_) => const MainScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
      },
    );
  }
}
