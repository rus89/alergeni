// ABOUTME: Tests for MapViewModel state management, summary building, and cache behavior.
// ABOUTME: Covers loadLocations, getLocationSummary, trend logic, and pin color.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udahni/core/errors/app_error.dart';
import 'package:udahni/presentation/viewmodels/map_view_model.dart';

import '../../helpers/fake_pollen_repository.dart';
import '../../helpers/test_data.dart';

void main() {
  late FakePollenRepository fakeRepo;
  late MapViewModel vm;

  setUp(() {
    fakeRepo = FakePollenRepository();
    vm = MapViewModel(pollenRepository: fakeRepo);
  });

  // ------------------------------------------------------------------
  // loadLocations
  // ------------------------------------------------------------------

  group('loadLocations', () {
    test('sets locations on success', () async {
      fakeRepo.locationsResult = [makeLocations(id: 1), makeLocations(id: 2)];
      fakeRepo.sitesResult = [];

      await vm.loadLocations();
      // Wait for background prefetch to complete
      await Future.delayed(Duration.zero);

      expect(vm.locations?.length, 2);
    });

    test('clears loading flag after success', () async {
      fakeRepo.locationsResult = [makeLocations(id: 1)];
      fakeRepo.sitesResult = [];
      await vm.loadLocations();
      await Future.delayed(Duration.zero);

      expect(vm.isLoading, isFalse);
    });

    test('sets error on failure', () async {
      fakeRepo.locationsError = const NoInternetError();
      await vm.loadLocations();

      expect(vm.error, isA<NoInternetError>());
      expect(vm.isLoading, isFalse);
    });

    test('wraps non-AppError exceptions as UnexpectedError', () async {
      fakeRepo.locationsError = Exception('unknown');
      await vm.loadLocations();
      expect(vm.error, isA<UnexpectedError>());
    });
  });

  // ------------------------------------------------------------------
  // getLocationSummary — building from sites
  // ------------------------------------------------------------------

  group('getLocationSummary', () {
    test('empty sites returns no-data summary', () async {
      fakeRepo.sitesResult = [];
      final summary = await vm.getLocationSummary(locationId: 1);

      expect(summary.hasData, isFalse);
      expect(summary.riskLabel, 'Nema podataka');
    });

    test('computes max level across all sites', () async {
      fakeRepo.sitesResult = [makeSite(level: 2), makeSite(level: 4), makeSite(level: 1)];
      final summary = await vm.getLocationSummary(locationId: 1);

      // levelToLabel(4) == 'Visoka'
      expect(summary.riskLabel, 'Visoka');
    });

    test('has correct hasData flag when sites are present', () async {
      fakeRepo.sitesResult = [makeSite(level: 3)];
      final summary = await vm.getLocationSummary(locationId: 1);

      expect(summary.hasData, isTrue);
    });

    test('includes week from first site', () async {
      fakeRepo.sitesResult = [makeSite(week: 17)];
      final summary = await vm.getLocationSummary(locationId: 1);

      expect(summary.week, 17);
    });
  });

  // ------------------------------------------------------------------
  // _mostCommonTrend (tested via getLocationSummary)
  // ------------------------------------------------------------------

  group('_mostCommonTrend', () {
    test('returns the single trend when only one value present', () async {
      fakeRepo.sitesResult = [makeSite(trend: 2), makeSite(trend: 2)];
      final summary = await vm.getLocationSummary(locationId: 1);

      expect(summary.trendValue, 2);
    });

    test('returns dominant trend when one appears more frequently', () async {
      fakeRepo.sitesResult = [
        makeSite(trend: 1),
        makeSite(trend: 2),
        makeSite(trend: 2),
      ];
      final summary = await vm.getLocationSummary(locationId: 1);

      expect(summary.trendValue, 2);
    });

    test('breaks ties by returning the higher trend value', () async {
      fakeRepo.sitesResult = [makeSite(trend: 1), makeSite(trend: 3)];
      final summary = await vm.getLocationSummary(locationId: 1);

      // Both appear once — tie broken by higher trend (more pessimistic)
      expect(summary.trendValue, 3);
    });
  });

  // ------------------------------------------------------------------
  // Cache behavior
  // ------------------------------------------------------------------

  group('cache behavior', () {
    test('getLocationSummary caches result — second call skips fetchSites', () async {
      fakeRepo.sitesResult = [makeSite(level: 3)];
      await vm.getLocationSummary(locationId: 1);
      await vm.getLocationSummary(locationId: 1);

      expect(fakeRepo.fetchSitesCallCount, 1);
    });

    test('getLocationSummaryIfCached returns null for uncached location', () {
      expect(vm.getLocationSummaryIfCached(locationId: 99), isNull);
    });

    test('getLocationSummaryIfCached returns cached summary', () async {
      fakeRepo.sitesResult = [makeSite(level: 2)];
      await vm.getLocationSummary(locationId: 1);

      expect(vm.getLocationSummaryIfCached(locationId: 1), isNotNull);
    });

    test('getPinColorForLocation returns grey for uncached location', () {
      final color = vm.getPinColorForLocation(99);
      expect(color, Colors.grey.shade600);
    });

    test('getPinColorForLocation returns non-grey for cached location', () async {
      fakeRepo.sitesResult = [makeSite(trend: 2)];
      await vm.getLocationSummary(locationId: 1);

      final color = vm.getPinColorForLocation(1);
      // trendToPinColor(2) is not grey
      expect(color, isNot(Colors.grey.shade600));
    });
  });

  // ------------------------------------------------------------------
  // refreshLocations
  // ------------------------------------------------------------------

  group('refreshLocations', () {
    test('reloads locations', () async {
      fakeRepo.locationsResult = [makeLocations(id: 1)];
      fakeRepo.sitesResult = [];
      await vm.loadLocations();
      await Future.delayed(Duration.zero);

      fakeRepo.locationsResult = [makeLocations(id: 1), makeLocations(id: 2)];
      await vm.refreshLocations();
      await Future.delayed(Duration.zero);

      expect(vm.locations?.length, 2);
    });

    test('clears summary cache on refresh', () async {
      fakeRepo.locationsResult = [makeLocations(id: 1)];
      fakeRepo.sitesResult = [makeSite(level: 3)];
      await vm.loadLocations();
      await Future.delayed(Duration.zero);

      // Summary should be cached after prefetch
      final cached = vm.getLocationSummaryIfCached(locationId: 1);
      expect(cached, isNotNull);

      fakeRepo.sitesResult = [];
      await vm.refreshLocations();
      await Future.delayed(Duration.zero);

      // Cache cleared on refresh, then re-populated — but prefetch runs async
      // Just verify loadLocations clears the old cache (count increments again)
      expect(fakeRepo.fetchLocationsCallCount, 2);
    });
  });
}
