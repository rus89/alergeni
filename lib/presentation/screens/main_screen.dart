// ABOUTME: Top-level scaffold for the app — owns the AppBar, NavigationBar, and tab routing.
// ABOUTME: The gear icon in the AppBar opens ProfileSettingsScreen.

import 'package:flutter/material.dart';
import 'package:udahni/presentation/screens/about_screen.dart';
import 'package:udahni/presentation/screens/home_screen.dart';
import 'package:udahni/presentation/screens/map_screen.dart';
import 'package:udahni/presentation/screens/profile_settings_screen.dart';

//--------------------------------------------------------------------------
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

//--------------------------------------------------------------------------
class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  static const _tabTitles = [
    'Početna',
    'Mapa mernih stanica',
    'O aplikaciji',
  ];

  final List<Widget> _screens = [
    const HomeScreen(),
    const MapScreen(),
    const AboutScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tabTitles[_currentIndex]),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Profil i podešavanja',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProfileSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Početna',
            tooltip: 'Početna',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mapa',
            tooltip: 'Mapa mernih stanica',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: 'O aplikaciji',
            tooltip: 'Informacije o aplikaciji',
          ),
        ],
      ),
    );
  }
}
