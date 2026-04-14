// ABOUTME: Tests for PollenRepository caching layer and delegation to PollenApiService.
// ABOUTME: Verifies that allergen and concentration caches work correctly.

import 'package:flutter_test/flutter_test.dart';
import 'package:udahni/data/repositories/pollen_repository.dart';

import '../../helpers/fake_pollen_api_service.dart';
import '../../helpers/test_data.dart';

void main() {
  late FakePollenApiService fakeApi;

  setUp(() {
    fakeApi = FakePollenApiService();
  });

  group('fetchAllergens — caching', () {
    test('first call fetches from API service', () async {
      fakeApi.allergensResult = [makeAllergen(id: 1), makeAllergen(id: 2)];
      final repo = _makeRepo(fakeApi);

      final result = await repo.fetchAllergens();

      expect(fakeApi.fetchAllergensCallCount, 1);
      expect(result.length, 2);
    });

    test('second call returns cached data without calling API service', () async {
      fakeApi.allergensResult = [makeAllergen(id: 1)];
      final repo = _makeRepo(fakeApi);

      await repo.fetchAllergens();
      final secondResult = await repo.fetchAllergens();

      expect(fakeApi.fetchAllergensCallCount, 1);
      expect(secondResult.length, 1);
    });

    test('cached data matches original fetch', () async {
      fakeApi.allergensResult = [makeAllergen(id: 5, name: 'Alnus')];
      final repo = _makeRepo(fakeApi);

      final first = await repo.fetchAllergens();
      final second = await repo.fetchAllergens();

      expect(second.first.id, first.first.id);
      expect(second.first.name, first.first.name);
    });
  });

  group('fetchConcentrationsByIds — caching', () {
    test('first call fetches all requested IDs from API', () async {
      fakeApi.concentrationsByIdsResult = [
        makeConcentrations(id: 1),
        makeConcentrations(id: 2),
      ];
      final repo = _makeRepo(fakeApi);

      final result = await repo.fetchConcentrationsByIds([1, 2]);

      expect(fakeApi.fetchConcentrationsByIdsCallCount, 1);
      expect(result.length, 2);
    });

    test('second call with same IDs returns from cache without API call', () async {
      fakeApi.concentrationsByIdsResult = [
        makeConcentrations(id: 1),
        makeConcentrations(id: 2),
      ];
      final repo = _makeRepo(fakeApi);

      await repo.fetchConcentrationsByIds([1, 2]);
      await repo.fetchConcentrationsByIds([1, 2]);

      expect(fakeApi.fetchConcentrationsByIdsCallCount, 1);
    });

    test('partial cache hit fetches only missing IDs', () async {
      final repo = _makeRepo(fakeApi);

      // First call caches IDs 1 and 2
      fakeApi.concentrationsByIdsResult = [
        makeConcentrations(id: 1),
        makeConcentrations(id: 2),
      ];
      await repo.fetchConcentrationsByIds([1, 2]);

      // Second call requests 2 and 3 — only 3 should be fetched
      fakeApi.concentrationsByIdsResult = [makeConcentrations(id: 3)];
      await repo.fetchConcentrationsByIds([2, 3]);

      expect(fakeApi.fetchConcentrationsByIdsCallCount, 2);
      // Second fetch should only have requested ID 3
      expect(fakeApi.fetchConcentrationsByIdsArgs.last, [3]);
    });

    test('returns results in input order', () async {
      fakeApi.concentrationsByIdsResult = [
        makeConcentrations(id: 3, value: 30),
        makeConcentrations(id: 1, value: 10),
        makeConcentrations(id: 2, value: 20),
      ];
      final repo = _makeRepo(fakeApi);

      final result = await repo.fetchConcentrationsByIds([1, 2, 3]);

      expect(result.map((c) => c.id).toList(), [1, 2, 3]);
    });

    test('cached results are returned in input order', () async {
      fakeApi.concentrationsByIdsResult = [
        makeConcentrations(id: 1),
        makeConcentrations(id: 2),
        makeConcentrations(id: 3),
      ];
      final repo = _makeRepo(fakeApi);

      await repo.fetchConcentrationsByIds([1, 2, 3]);
      // Request same IDs in different order
      final result = await repo.fetchConcentrationsByIds([3, 1, 2]);

      expect(result.map((c) => c.id).toList(), [3, 1, 2]);
    });
  });

  group('pass-through methods', () {
    test('fetchLocations delegates to API service', () async {
      fakeApi.locationsResult = [makeLocations(id: 1), makeLocations(id: 2)];
      final repo = _makeRepo(fakeApi);

      final result = await repo.fetchLocations();

      expect(fakeApi.fetchLocationsCallCount, 1);
      expect(result.length, 2);
    });

    test('fetchSites delegates to API service', () async {
      fakeApi.sitesResult = [makeSite(locationId: 1, allergenId: 3)];
      final repo = _makeRepo(fakeApi);

      final result = await repo.fetchSites(locationId: 1);

      expect(fakeApi.fetchSitesCallCount, 1);
      expect(result.length, 1);
      expect(result.first.allergenId, 3);
    });

    test('fetchPollensByLocationAndDate delegates to API service', () async {
      fakeApi.pollensResult = makePaginatedResponse(
        count: 1,
        results: [makePollens(id: 1, locationId: 5)],
      );
      final repo = _makeRepo(fakeApi);

      final result = await repo.fetchPollensByLocationAndDate(5, '2026-04-01');

      expect(result.results.length, 1);
      expect(result.results.first.locationId, 5);
    });
  });
}

// Creates a PollenRepository backed by the given fake API service.
_PollenRepositoryWithFake _makeRepo(FakePollenApiService fakeApi) {
  return _PollenRepositoryWithFake(fakeApi);
}

// PollenRepository accepts PollenApiService? — we subclass to pass the fake in.
class _PollenRepositoryWithFake extends PollenRepository {
  _PollenRepositoryWithFake(FakePollenApiService fakeApi)
      : super(apiService: fakeApi);
}
