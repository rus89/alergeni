// ABOUTME: Tests for HomeViewModel state management, data loading, and severity logic.
// ABOUTME: Covers location selection, fallback strategy, severity counts, typeDataMap, and errors.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udahni/core/errors/app_error.dart';
import 'package:udahni/data/models/allergen.dart';
import 'package:udahni/data/models/concentrations.dart';
import 'package:udahni/data/models/site.dart';
import 'package:udahni/presentation/viewmodels/home_view_model.dart';

import '../../helpers/fake_pollen_repository.dart';
import '../../helpers/test_data.dart';

void main() {
  late FakePollenRepository fakeRepo;
  late HomeViewModel vm;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeRepo = FakePollenRepository();
    vm = HomeViewModel(pollenRepository: fakeRepo);
  });

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------

  // Loads a single location, allergens, and optionally pollen data.
  Future<void> loadData({
    List<Allergen> allergens = const [],
    List<Concentrations> concentrations = const [],
    List<Site> sites = const [],
    DateTime? pollenDate,
  }) async {
    fakeRepo.locationsResult = [makeLocations(id: 1)];
    fakeRepo.allergensResult = allergens;
    fakeRepo.allergenTypesResult = [];
    fakeRepo.concentrationsByIdsResult = concentrations;
    fakeRepo.sitesResult = sites;

    if (concentrations.isNotEmpty) {
      final concIds = concentrations.map((c) => c.id).toList();
      fakeRepo.pollensByLocationAndDateResult = makePaginatedResponse(
        count: 1,
        results: [
          makePollens(
            id: 1,
            locationId: 1,
            concentrationIds: concIds,
            date: pollenDate,
          ),
        ],
      );
    }

    await vm.fetchLocations();
    if (allergens.isNotEmpty) await vm.fetchAllergens();
    if (concentrations.isNotEmpty) await vm.fetchPollenData();
  }

  // ------------------------------------------------------------------
  // fetchLocations — location selection
  // ------------------------------------------------------------------

  group('fetchLocations — location selection', () {
    test('selects first location when no preference saved', () async {
      fakeRepo.locationsResult = [makeLocations(id: 1), makeLocations(id: 2)];
      await vm.fetchLocations();
      expect(vm.selectedLocation?.id, 1);
    });

    test('restores saved location from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'selected_location_id': 2});
      fakeRepo.locationsResult = [makeLocations(id: 1), makeLocations(id: 2)];
      await vm.fetchLocations();
      expect(vm.selectedLocation?.id, 2);
    });

    test('falls back to first location when saved ID not found', () async {
      SharedPreferences.setMockInitialValues({'selected_location_id': 99});
      fakeRepo.locationsResult = [makeLocations(id: 1), makeLocations(id: 2)];
      await vm.fetchLocations();
      expect(vm.selectedLocation?.id, 1);
    });

    test('sets locations error on failure', () async {
      fakeRepo.locationsError = const NoInternetError();
      await vm.fetchLocations();
      expect(vm.error, isA<NoInternetError>());
    });

    test('selectedLocation is null when locations list is empty', () async {
      fakeRepo.locationsResult = [];
      await vm.fetchLocations();
      expect(vm.selectedLocation, isNull);
    });
  });

  // ------------------------------------------------------------------
  // getOverallStatus / getOverallStatusColor
  // ------------------------------------------------------------------

  group('getOverallStatus', () {
    test('returns Visok when any high concentration', () async {
      await loadData(concentrations: [
        makeConcentrations(id: 1, value: 51),
        makeConcentrations(id: 2, value: 5),
      ]);
      expect(vm.getOverallStatus(), 'Visok');
    });

    test('returns Srednji when medium but no high', () async {
      await loadData(concentrations: [
        makeConcentrations(id: 1, value: 20),
        makeConcentrations(id: 2, value: 5),
      ]);
      expect(vm.getOverallStatus(), 'Srednji');
    });

    test('returns Nizak when only low concentrations', () async {
      await loadData(concentrations: [
        makeConcentrations(id: 1, value: 1),
        makeConcentrations(id: 2, value: 10),
      ]);
      expect(vm.getOverallStatus(), 'Nizak');
    });

    test('returns Nema koncentracije when all zero', () async {
      await loadData(concentrations: [
        makeConcentrations(id: 1, value: 0),
        makeConcentrations(id: 2, value: 0),
      ]);
      // All zeros → no positive → snapshot skipped → state cleared
      expect(vm.getOverallStatus(), 'Nema koncentracije');
    });
  });

  group('getOverallStatusColor', () {
    test('returns red for high', () async {
      await loadData(concentrations: [makeConcentrations(id: 1, value: 100)]);
      expect(vm.getOverallStatusColor(), Colors.red);
    });

    test('returns orange for medium', () async {
      await loadData(concentrations: [makeConcentrations(id: 1, value: 30)]);
      expect(vm.getOverallStatusColor(), Colors.orange);
    });

    test('returns green for low', () async {
      await loadData(concentrations: [makeConcentrations(id: 1, value: 5)]);
      expect(vm.getOverallStatusColor(), Colors.green);
    });

    test('returns grey when no concentrations', () async {
      fakeRepo.locationsResult = [makeLocations(id: 1)];
      await vm.fetchLocations();
      expect(vm.getOverallStatusColor(), Colors.grey);
    });
  });

  // ------------------------------------------------------------------
  // Severity counting
  // ------------------------------------------------------------------

  group('severity counting', () {
    test('correctly counts low concentrations (1-10)', () async {
      await loadData(concentrations: [
        makeConcentrations(id: 1, value: 1),
        makeConcentrations(id: 2, value: 10),
        makeConcentrations(id: 3, value: 5),
      ]);
      expect(vm.lowCount, 3);
      expect(vm.mediumCount, 0);
      expect(vm.highCount, 0);
    });

    test('correctly counts medium concentrations (11-50)', () async {
      await loadData(concentrations: [
        makeConcentrations(id: 1, value: 11),
        makeConcentrations(id: 2, value: 50),
      ]);
      expect(vm.lowCount, 0);
      expect(vm.mediumCount, 2);
      expect(vm.highCount, 0);
    });

    test('correctly counts high concentrations (51+)', () async {
      await loadData(concentrations: [
        makeConcentrations(id: 1, value: 51),
        makeConcentrations(id: 2, value: 200),
      ]);
      expect(vm.lowCount, 0);
      expect(vm.mediumCount, 0);
      expect(vm.highCount, 2);
    });

    test('does not count zero-value concentrations', () async {
      await loadData(concentrations: [
        makeConcentrations(id: 1, value: 0),
        makeConcentrations(id: 2, value: 0),
      ]);
      // All zeros → no positive snapshot → counts remain 0
      expect(vm.lowCount, 0);
      expect(vm.mediumCount, 0);
      expect(vm.highCount, 0);
    });

    test('bins mixed values across all bands', () async {
      await loadData(concentrations: [
        makeConcentrations(id: 1, value: 5),   // low
        makeConcentrations(id: 2, value: 25),  // medium
        makeConcentrations(id: 3, value: 75),  // high
        makeConcentrations(id: 4, value: 0),   // not counted
      ]);
      expect(vm.lowCount, 1);
      expect(vm.mediumCount, 1);
      expect(vm.highCount, 1);
    });
  });

  // ------------------------------------------------------------------
  // Data fallback strategy
  // ------------------------------------------------------------------

  group('data fallback strategy', () {
    test('uses today\'s data when available', () async {
      fakeRepo.locationsResult = [makeLocations(id: 1)];
      fakeRepo.concentrationsByIdsResult = [makeConcentrations(id: 1, value: 5)];
      fakeRepo.pollensByLocationAndDateResult = makePaginatedResponse(
        count: 1,
        results: [makePollens(id: 1, locationId: 1, concentrationIds: [1])],
      );
      fakeRepo.sitesResult = [];

      await vm.fetchLocations();
      await vm.fetchPollenData();

      // fetchRecentPollensByLocation should NOT have been called
      expect(fakeRepo.recentPollensByLocationCallCount, 0);
      expect(vm.lowCount, 1);
    });

    test('falls back to 1-year window when today is empty', () async {
      fakeRepo.locationsResult = [makeLocations(id: 1)];
      // Today returns empty
      fakeRepo.pollensByLocationAndDateResult = makePaginatedResponse(results: []);
      // First recent call returns data
      fakeRepo.recentPollensByLocationResult = makePaginatedResponse(
        count: 1,
        results: [makePollens(id: 1, locationId: 1, concentrationIds: [1])],
      );
      fakeRepo.concentrationsByIdsResult = [makeConcentrations(id: 1, value: 5)];
      fakeRepo.sitesResult = [];

      await vm.fetchLocations();
      await vm.fetchPollenData();

      expect(fakeRepo.recentPollensByLocationCallCount, 1);
      expect(vm.lowCount, 1);
    });

    test('falls back to 2-year window when 1-year is also empty', () async {
      fakeRepo.locationsResult = [makeLocations(id: 1)];
      fakeRepo.pollensByLocationAndDateResult = makePaginatedResponse(results: []);
      // First recent call (1-year) returns empty; second (2-year) returns data
      fakeRepo.recentPollensQueue.add(makePaginatedResponse(results: []));
      fakeRepo.recentPollensByLocationResult = makePaginatedResponse(
        count: 1,
        results: [makePollens(id: 1, locationId: 1, concentrationIds: [1])],
      );
      fakeRepo.concentrationsByIdsResult = [makeConcentrations(id: 1, value: 5)];
      fakeRepo.sitesResult = [];

      await vm.fetchLocations();
      await vm.fetchPollenData();

      expect(fakeRepo.recentPollensByLocationCallCount, 2);
      expect(vm.lowCount, 1);
    });

    test('clears state when all windows return empty', () async {
      fakeRepo.locationsResult = [makeLocations(id: 1)];
      fakeRepo.pollensByLocationAndDateResult = makePaginatedResponse(results: []);
      fakeRepo.recentPollensByLocationResult = makePaginatedResponse(results: []);
      fakeRepo.sitesResult = [];

      await vm.fetchLocations();
      await vm.fetchPollenData();

      expect(vm.concentrations, isNull);
      expect(vm.selectedDate, isNull);
    });
  });

  // ------------------------------------------------------------------
  // Snapshot selection
  // ------------------------------------------------------------------

  group('snapshot selection', () {
    test('skips pollen with empty concentration IDs', () async {
      fakeRepo.locationsResult = [makeLocations(id: 1)];
      fakeRepo.pollensByLocationAndDateResult = makePaginatedResponse(
        count: 1,
        results: [makePollens(id: 1, locationId: 1, concentrationIds: [])],
      );
      fakeRepo.sitesResult = [];

      await vm.fetchLocations();
      await vm.fetchPollenData();

      expect(vm.concentrations, isNull);
    });

    test('skips pollen where all concentrations are zero', () async {
      fakeRepo.locationsResult = [makeLocations(id: 1)];
      fakeRepo.pollensByLocationAndDateResult = makePaginatedResponse(
        count: 1,
        results: [makePollens(id: 1, locationId: 1, concentrationIds: [1])],
      );
      fakeRepo.concentrationsByIdsResult = [makeConcentrations(id: 1, value: 0)];
      fakeRepo.sitesResult = [];

      await vm.fetchLocations();
      await vm.fetchPollenData();

      expect(vm.concentrations, isNull);
    });

    test('selects pollen with positive concentrations', () async {
      await loadData(concentrations: [makeConcentrations(id: 1, value: 15)]);
      expect(vm.concentrations, isNotNull);
      expect(vm.concentrations!.first.value, 15);
    });
  });

  // ------------------------------------------------------------------
  // typeDataMap
  // ------------------------------------------------------------------

  group('typeDataMap', () {
    test('returns empty map when allergens or concentrations are null', () async {
      fakeRepo.locationsResult = [makeLocations(id: 1)];
      await vm.fetchLocations();
      expect(vm.typeDataMap, isEmpty);
    });

    test('returns Nema for type with no positive concentrations', () async {
      await loadData(
        allergens: [makeAllergen(id: 1, type: 1)],
        concentrations: [makeConcentrations(id: 1, allergenId: 1, value: 0)],
      );
      // All zeros skipped → typeDataMap[1] should be 'Nema'
      // But zeros skip the snapshot entirely → concentrations is null → typeDataMap empty
      // Use a positive + a zero for a different allergen:
      // ... This test needs at least one positive to populate concentrations.
      // Reset with a positive conc for type 2 and check type 1 shows Nema.
      final repo2 = FakePollenRepository();
      SharedPreferences.setMockInitialValues({});
      final vm2 = HomeViewModel(pollenRepository: repo2);
      repo2.locationsResult = [makeLocations(id: 1)];
      repo2.allergensResult = [
        makeAllergen(id: 1, type: 1), // tree
        makeAllergen(id: 2, type: 2), // grass
      ];
      repo2.concentrationsByIdsResult = [
        makeConcentrations(id: 1, allergenId: 1, value: 0), // type 1 = 0
        makeConcentrations(id: 2, allergenId: 2, value: 10), // type 2 positive
      ];
      repo2.pollensByLocationAndDateResult = makePaginatedResponse(
        count: 1,
        results: [makePollens(id: 1, locationId: 1, concentrationIds: [1, 2])],
      );
      repo2.sitesResult = [];
      await vm2.fetchLocations();
      await vm2.fetchAllergens();
      await vm2.fetchPollenData();

      expect(vm2.typeDataMap[1]?.severity, 'Nema'); // tree has no positive data
      expect(vm2.typeDataMap[2]?.severity, isNot('Nema')); // grass has data
    });

    test('groups concentrations by allergen type', () async {
      await loadData(
        allergens: [
          makeAllergen(id: 1, type: 1), // tree
          makeAllergen(id: 2, type: 2), // grass
        ],
        concentrations: [
          makeConcentrations(id: 1, allergenId: 1, value: 5),
          makeConcentrations(id: 2, allergenId: 2, value: 20),
        ],
      );
      expect(vm.typeDataMap.containsKey(1), isTrue); // tree
      expect(vm.typeDataMap.containsKey(2), isTrue); // grass
    });

    test('sorts allergens by danger score to pick most dangerous', () async {
      // allergenA: allergenicityIndex=3, concentration=5, danger=15
      // allergenB: allergenicityIndex=1, concentration=20, danger=20 ← wins
      await loadData(
        allergens: [
          makeAllergen(id: 1, type: 1, allergenicityIndex: 3),
          makeAllergen(id: 2, type: 1, allergenicityIndex: 1),
        ],
        concentrations: [
          makeConcentrations(id: 1, allergenId: 1, value: 5),
          makeConcentrations(id: 2, allergenId: 2, value: 20),
        ],
      );
      // Both are type 1. Most dangerous = allergenB (danger 20).
      // concentration 20 falls in medium (11-50), concentrationLabel = 'Srednja'
      expect(vm.typeDataMap[1]?.severity, 'Srednja');
    });

    test('skips zero-value concentrations in typeDataMap', () async {
      await loadData(
        allergens: [
          makeAllergen(id: 1, type: 1),
          makeAllergen(id: 2, type: 1),
        ],
        concentrations: [
          makeConcentrations(id: 1, allergenId: 1, value: 0),
          makeConcentrations(id: 2, allergenId: 2, value: 10),
        ],
      );
      // allergen id=1 (value 0) is skipped; id=2 (value 10) contributes
      // concentrationLabel(10) = 'Niska'
      expect(vm.typeDataMap[1]?.severity, 'Niska');
    });
  });

  // ------------------------------------------------------------------
  // fiveTierLevel / getFiveTierColor
  // ------------------------------------------------------------------

  group('fiveTierLevel', () {
    test('falls back to getOverallStatus when no site data', () async {
      await loadData(concentrations: [makeConcentrations(id: 1, value: 5)]);
      expect(vm.siteData, isEmpty);
      expect(vm.fiveTierLevel, vm.getOverallStatus());
    });

    test('uses max level from site data', () async {
      await loadData(
        concentrations: [makeConcentrations(id: 1, value: 5)],
        sites: [makeSite(level: 2), makeSite(level: 4)],
      );
      // levelToLabel(4) == 'Visoka'
      expect(vm.fiveTierLevel, 'Visoka');
    });

    test('getFiveTierColor falls back to getOverallStatusColor when no site data', () async {
      await loadData(concentrations: [makeConcentrations(id: 1, value: 5)]);
      expect(vm.getFiveTierColor(), vm.getOverallStatusColor());
    });
  });

  // ------------------------------------------------------------------
  // isShowingHistoricalData
  // ------------------------------------------------------------------

  group('isShowingHistoricalData', () {
    test('returns false when no pollen loaded', () async {
      expect(vm.isShowingHistoricalData, isFalse);
    });

    test('returns false when pollen date is within 7 days', () async {
      await loadData(
        concentrations: [makeConcentrations(id: 1, value: 5)],
        pollenDate: DateTime.now(),
      );
      expect(vm.isShowingHistoricalData, isFalse);
    });

    test('returns true when pollen date is older than 7 days', () async {
      await loadData(
        concentrations: [makeConcentrations(id: 1, value: 5)],
        pollenDate: DateTime.now().subtract(const Duration(days: 8)),
      );
      expect(vm.isShowingHistoricalData, isTrue);
    });
  });

  // ------------------------------------------------------------------
  // Error handling
  // ------------------------------------------------------------------

  group('error handling', () {
    test('error getter returns locations error first', () async {
      fakeRepo.locationsError = const NoInternetError();
      fakeRepo.allergensError = const ServerError();
      await vm.fetchLocations();
      await vm.fetchAllergens();
      expect(vm.error, isA<NoInternetError>());
    });

    test('error getter returns allergens error when no locations error', () async {
      fakeRepo.locationsResult = [makeLocations(id: 1)];
      fakeRepo.allergensError = const ServerError();
      await vm.fetchLocations();
      await vm.fetchAllergens();
      expect(vm.error, isA<ServerError>());
    });

    test('wraps non-AppError exceptions as UnexpectedError', () async {
      fakeRepo.locationsError = Exception('unknown');
      await vm.fetchLocations();
      expect(vm.error, isA<UnexpectedError>());
    });
  });

  // ------------------------------------------------------------------
  // Location persistence
  // ------------------------------------------------------------------

  group('location persistence', () {
    test('selectLocation saves ID to SharedPreferences', () async {
      fakeRepo.locationsResult = [makeLocations(id: 1)];
      fakeRepo.sitesResult = [];
      fakeRepo.pollensByLocationAndDateResult = makePaginatedResponse(results: []);
      fakeRepo.recentPollensByLocationResult = makePaginatedResponse(results: []);
      await vm.fetchLocations();

      vm.selectLocation(makeLocations(id: 7));
      // Allow the async save to complete
      await Future.delayed(Duration.zero);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('selected_location_id'), 7);
    });

    test('startup restores saved location ID', () async {
      SharedPreferences.setMockInitialValues({'selected_location_id': 2});
      final repo2 = FakePollenRepository();
      final vm2 = HomeViewModel(pollenRepository: repo2);
      repo2.locationsResult = [makeLocations(id: 1), makeLocations(id: 2)];

      await vm2.fetchLocations();

      expect(vm2.selectedLocation?.id, 2);
    });
  });
}
