// ABOUTME: Tests for OnboardingService — SharedPreferences-backed onboarding state.
// ABOUTME: Covers completion tracking and per-screen visit tracking.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udahni/core/services/onboarding_service.dart';

void main() {
  group('OnboardingService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('isOnboardingComplete returns false on fresh state', () async {
      final service = OnboardingService();
      expect(await service.isOnboardingComplete(), isFalse);
    });

    test('isOnboardingComplete returns true after markOnboardingComplete', () async {
      final service = OnboardingService();
      await service.markOnboardingComplete();
      expect(await service.isOnboardingComplete(), isTrue);
    });

    test('resetOnboarding reverts completion to false', () async {
      final service = OnboardingService();
      await service.markOnboardingComplete();
      await service.resetOnboarding();
      expect(await service.isOnboardingComplete(), isFalse);
    });

    test('hasVisitedScreen returns false for unvisited screen', () async {
      final service = OnboardingService();
      expect(await service.hasVisitedScreen('home'), isFalse);
    });

    test('hasVisitedScreen returns true after markScreenVisited', () async {
      final service = OnboardingService();
      await service.markScreenVisited('home');
      expect(await service.hasVisitedScreen('home'), isTrue);
    });

    test('markScreenVisited does not affect other screens', () async {
      final service = OnboardingService();
      await service.markScreenVisited('home');
      expect(await service.hasVisitedScreen('map'), isFalse);
    });

    test('resetOnboarding clears visited screens', () async {
      final service = OnboardingService();
      await service.markScreenVisited('home');
      await service.resetOnboarding();
      expect(await service.hasVisitedScreen('home'), isFalse);
    });
  });
}
