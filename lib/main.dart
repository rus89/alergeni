import 'package:alergeni/core/theme/app_theme.dart';
import 'package:alergeni/data/repositories/pollen_repository.dart';
import 'package:alergeni/presentation/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//--------------------------------------------------------------------------
void main() {
  runApp(
    Provider<PollenRepository>(
      create: (_) => PollenRepository(),
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
