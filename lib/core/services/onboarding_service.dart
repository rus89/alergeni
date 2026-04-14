// ABOUTME: Persists onboarding state: whether intro has been seen and which screens have been visited.
// ABOUTME: Wraps SharedPreferences — no business logic, reads and writes only.

import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _visitedScreensKey = 'visited_screens';

  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  Future<void> markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, true);
  }

  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, false);
    await prefs.remove(_visitedScreensKey);
  }

  Future<bool> hasVisitedScreen(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final visited = prefs.getStringList(_visitedScreensKey) ?? [];
    return visited.contains(key);
  }

  Future<void> markScreenVisited(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final visited = List<String>.from(
      prefs.getStringList(_visitedScreensKey) ?? [],
    );
    if (!visited.contains(key)) {
      visited.add(key);
      await prefs.setStringList(_visitedScreensKey, visited);
    }
  }
}
