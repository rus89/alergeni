// ABOUTME: Hand-written fake for OnboardingService for use in widget tests.
// ABOUTME: Tracks calls and returns configurable values without SharedPreferences.

import 'package:udahni/core/services/onboarding_service.dart';

class FakeOnboardingService implements OnboardingService {
  bool _complete;
  bool completeCalled = false;
  bool resetCalled = false;
  bool markScreenVisitedCalled = false;
  String? lastMarkScreenVisitedKey;
  final Set<String> _visitedScreens = {};

  FakeOnboardingService({bool isComplete = false}) : _complete = isComplete;

  @override
  Future<bool> isOnboardingComplete() async => _complete;

  @override
  Future<void> markOnboardingComplete() async {
    completeCalled = true;
    _complete = true;
  }

  @override
  Future<void> resetOnboarding() async {
    resetCalled = true;
    _complete = false;
    _visitedScreens.clear();
  }

  @override
  Future<bool> hasVisitedScreen(String key) async =>
      _visitedScreens.contains(key);

  @override
  Future<void> markScreenVisited(String key) async {
    markScreenVisitedCalled = true;
    lastMarkScreenVisitedKey = key;
    _visitedScreens.add(key);
  }
}
