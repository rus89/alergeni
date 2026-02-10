import 'package:alergeni/core/theme/app_theme.dart';
import 'package:alergeni/data/repositories/pollen_repository.dart';
import 'package:alergeni/presentation/screens/main_screen.dart';
import 'package:alergeni/presentation/viewmodels/home_view_model.dart';
import 'package:alergeni/presentation/viewmodels/map_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//--------------------------------------------------------------------------
void main() {
  final pollenRepository = PollenRepository();

  runApp(
    MultiProvider(
      providers: [
        Provider<PollenRepository>.value(value: pollenRepository),
        ChangeNotifierProvider(
          create: (_) =>
              HomeViewModel(pollenRepository: pollenRepository)
                ..loadInitialData(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              MapViewModel(pollenRepository: pollenRepository)..loadLocations(),
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
