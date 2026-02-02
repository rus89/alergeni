import 'package:alergeni/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';

//--------------------------------------------------------------------------
void main() {
  runApp(const AllergenApp());
}

//--------------------------------------------------------------------------
class AllergenApp extends StatelessWidget {
  const AllergenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Udahni',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
