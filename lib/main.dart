import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:udahni/core/theme/app_theme.dart';
import 'package:udahni/data/repositories/pollen_repository.dart';
import 'package:udahni/presentation/screens/main_screen.dart';
import 'package:udahni/presentation/viewmodels/home_view_model.dart';
import 'package:udahni/presentation/viewmodels/map_view_model.dart';
import 'package:udahni/presentation/viewmodels/personal_allergen_view_model.dart';

//--------------------------------------------------------------------------
void main() {
  final pollenRepository = PollenRepository();

  runApp(
    MultiProvider(
      providers: [
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
      child: const AllergenApp(),
    ),
  );
}

//--------------------------------------------------------------------------
class AllergenApp extends StatelessWidget {
  const AllergenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Udahni',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainScreen(),
    );
  }
}
