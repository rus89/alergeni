# Context

Udahni has 36 source files but only 2 test files covering the simplest units (AppError +
PersonalAllergenViewModel). HomeViewModel (606 lines), PollenApiService (420 lines),
PollenRepository caching, and MapViewModel have zero tests. This plan adds ~170 tests across
14 new test files + 3 helpers in 4 independent phases, each leaving the suite green.
Zero new dependencies. http/testing.dart (ships with http ^1.6.0) provides MockClient.
fakeAsync is re-exported by package:flutter_test/flutter_test.dart. Hand-written fakes for
repo/VM layers per existing project convention (see PersonalAllergenViewModel test).

# Decisions confirmed against source

DecisionBasisNo mocktailMockClient covers API; hand-written fakes for repo/VMDefer selectNearestLocationFromDeviceCalls Geolocator statics directly — needs abstractionAccept DateTime.now() in tests_isOffSeason + \_fetchPreferredPollensForLocation use it. Not worth clock injectionSharedPreferences.setMockInitialValues({}) in setUpHomeViewModel calls SharedPreferences.getInstance() directly, same pattern as existing personal_allergen_view_model_test.dartApiConfig.maxRetries = 3Means 4 total attempts (loop: attempt <= maxRetries). Retry tests must pump 3 × delay (300ms, 600ms, 1200ms) with fakeAsyncAllergenTypeHelper.getIconForType returns Icon widgetTests compare .icon property, not the widget object itself

# Dependency graph

```
Phase 1: Pure logic (no deps)
└─ test_data.dart helpers
└─ level/severity/allergen_type helper tests
└─ model fromJson/toJson tests

Phase 2: PollenApiService (uses MockClient from http/testing.dart)

Phase 3: PollenRepository (uses FakePollenApiService from Phase 2/3)
└─ fake_pollen_api_service.dart

Phase 4: ViewModels (uses FakePollenRepository from Phase 4)
└─ fake_pollen_repository.dart
└─ home_view_model_test.dart
└─ map_view_model_test.dart
```

# Shared test infrastructure

`test/helpers/test_data.dart`
Factory functions. Every test uses these instead of inline maps.

```dart
// ABOUTME: Factory functions for constructing test model instances with sensible defaults.
// ABOUTME: Eliminates repetitive JSON construction across all test files.

Allergen makeAllergen({int id = 1, String name = 'Birch', String localizedName = 'Breza',
int type = 1, int allergenicityIndex = 2, String allergenicityDisplay = 'moderate',
int marginTop = 0, int marginBottom = 0})

AllergenTypes makeAllergenTypes({int id = 1, String name = 'Tree'})

Concentrations makeConcentrations({int id = 1, int allergenId = 1, int value = 5, int pollenId = 1})

Locations makeLocations({int id = 1, String name = 'Beograd', double latitude = 44.8,
double longitude = 20.4, String description = ''})

Pollens makePollens({int id = 1, int locationId = 1, DateTime? date, List<int> concentrationIds = const [1]})

Site makeSite({int locationId = 1, int allergenId = 1, int level = 2, int trend = 2,
int week = 10, int allergenicityIndex = 2, String? date, String? allergenName})

PaginatedResponse<T> makePaginatedResponse<T>({int count = 0, String? next, String? previous,
List<T> results = const []})
```

---

# Phase 1: Pure logic (~70 tests, 10 files)

No mocking, no dependencies. All import only from lib/ and test/helpers/test_data.dart.

## Helper tests

`test/core/helpers/level_helper_test.dart` (~12 tests)

- levelToLabel: each of 1–5 → correct Serbian label, unknown value → 'Nepoznato'
- levelToColor: each of 1–5 → specific Color constant, unknown → grey
- trendToLabel: 1/2/3 → correct label, null → 'Trend nije dostupan'
- trendToIcon: 1/2/3 → correct IconData, null → Icons.help_outline
- trendToPinColor: 1 → green, 2 → orange, 3 → red, null → Colors.grey.shade600

test/core/helpers/severity_helper_test.dart (~15 tests)

- concentrationLabel: 0 → 'Nema', 1 → 'Niska', 10 → 'Niska', 11 → 'Srednja', 50 → 'Srednja', 51 → 'Visoka'
- allergenicityBaseColor: 1/2/3 → AppTheme colors, unknown → grey
- allergenicityColorForConcentration: low/medium/high concentration × index 1/2/3 — verifies lightened vs base color
- allergenicityLabel: 1 → 'Slab', 2 → 'Srednji', 3 → 'Jak', unknown → 'Nepoznato'

test/core/helpers/allergen_type_helper_test.dart (~8 tests)

- getIconForType: compare .icon property (not widget) for IDs 1/2/3/unknown
- getLocalizedNameForType: 1 → 'Drveće', 2 → 'Trave', 3 → 'Korov', unknown → 'Nepoznato'
- getColorForType: 1 → green, 2 → lightGreen, 3 → orange, unknown → grey

## Model tests

test/data/models/allergen_test.dart (~10 tests)

- fromJson: maps allergenicity → allergenicityIndex, margine_top → marginTop (verify JSON key spellings)
- toJson round-trip
- allergenicityDisplayLocalized: 'mild', 'low', 'slab', 'nizak' → 'Nizak'; 'moderate', 'medium', 'umeren', 'srednji', 'srednja' → 'Srednji'; 'severe', 'high', 'jak', 'visok', 'visoka' → 'Visok'; unrecognized → pass-through; whitespace trimmed

test/data/models/allergen_types_test.dart (~3 tests): fromJson/toJson round-trip
test/data/models/concentrations_test.dart (~3 tests): fromJson/toJson; JSON key allergen → allergenId, pollen → pollenId
test/data/models/locations_test.dart (~6 tests): fromJson/toJson; double.tryParse fallback for string lat/lng; equality by id (same id, different name = equal); different id = not equal
test/data/models/paginated_response_test.dart (~5 tests): fromJson with typed results; hasNextPage true/false; hasPreviousPage true/false; null next/previous
test/data/models/pollens_test.dart (~4 tests): fromJson date parsing; toJson outputs ISO date string (no time component); concentrationIds round-trip
test/data/models/site_test.dart (~4 tests): fromJson; nullable date and allergenName; toJson

Production code changes: None.

---

# Phase 2: PollenApiService (~35 tests, 1 file)

File: test/data/services/pollen_api_service_test.dart

```dart
import 'package:http/testing.dart';

final requests = <http.Request>[];
final client = MockClient((request) async {
requests.add(request);
return http.Response(jsonEncode(responseData), statusCode);
});
final service = PollenApiService(httpClient: client, baseUrl: 'http://test');
```

Note: ApiConfig.maxRetries = 3 at runtime. Tests run in env where dart-define isn't set, so int.fromEnvironment('API_MAX_RETRIES', defaultValue: 3) = 3. Use fakeAsync + FakeAsync.elapse to advance past retry delays (300ms, 600ms, 1200ms).

Retry logic (~10 tests) — all use fakeAsync:

- 200 on first attempt → no retry, request count = 1
- 500 on first attempt, 200 on second → succeeds, request count = 2
- 408 retried; 429 retried
- 400 not retried (request count = 1, throws)
- 404 not retried
- SocketException on all attempts → throws NoInternetError
- TimeoutException on all attempts → throws NoInternetError
- After max retries exhausted on 500 → throws ServerError
- http.ClientException → throws NoInternetError (via AppError.fromException)

Response handling (~5 tests):

- 200 → parsed result
- 500 → ServerError
- 404 → NotFoundError
- 400 → UnexpectedError
- Malformed JSON on 200 → throws (verify it doesn't silently return null)

URL construction (~8 tests) — verify request.url.toString():

- fetchAllergenTypes → http://test/allergen-types/
- fetchLocations → http://test/locations/
- fetchPollensByLocationAndDate(1, '2024-03-15') → contains location=1&date=2024-03-15
- fetchRecentPollensByLocation(1) → no date_after param
- fetchRecentPollensByLocation(1, dateAfter: '2024-01-01') → has date_after=2024-01-01
- fetchSites(locationId: 1) with baseUrl containing /opendata → URL strips /opendata and hits /api/site/1/
- fetchPollens(page: 2) → has page=2

fetchConcentrationsByIds fallback (~8 tests):

- Empty list → returns [], no HTTP requests
- Duplicate IDs deduplicated before fetching
- Strategy 1 (id\_\_in=) returns all → done (2 requests: strategy 1 tried first)
- Strategy 1 fails (throws), strategy 2 (id=1&id=2) returns all → succeeds
- Both batch strategies fail → falls through to chunked individual fetchConcentrationById calls
- Individual fallback resolves all → returns correctly ordered by input
- All strategies fail for some ID → throws Exception
- Handles both paginated {results: [...]} and flat [...] responses

Production code changes: None.

# Phase 3: PollenRepository (~15 tests, 1 file + 1 helper)

test/helpers/fake_pollen_api_service.dart

```dart
// ABOUTME: Configurable fake for PollenApiService used in repository and ViewModel tests.
// ABOUTME: Tracks call counts and returns preconfigured responses or throws on demand.

class FakePollenApiService extends PollenApiService {
// Passes a throwing client to super — ensures no accidental HTTP calls.
FakePollenApiService() : super(httpClient: \_ThrowingClient(), baseUrl: 'http://fake');

List<Allergen> allergensResponse = [];
List<Concentrations> concentrationsResponse = [];
List<Locations> locationsResponse = [];
List<Site> sitesResponse = [];
int fetchAllergenCallCount = 0;
int fetchConcentrationsByIdsCallCount = 0;
// ... etc.

@override
Future<List<Allergen>> fetchAllergens() async {
fetchAllergenCallCount++;
return allergensResponse;
}
// override all other methods similarly
}
```

test/data/repositories/pollen_repository_test.dart

Allergen caching (~4 tests):

- First fetchAllergens call → delegates to API service (call count = 1)
- Second call → returns from cache, API service call count still 1
- Returns same data both times
- Cache returns list in stable order

Concentration caching (~6 tests):

- First call with [1, 2, 3] → fetches all 3 from API
- Second call with [1, 2, 3] → API call count unchanged
- Partial hit: first call [1, 2], second call [2, 3] → second call fetches only [3]
- Duplicate IDs in input ([1, 1, 2]) → only unique IDs fetched
- Results ordered by input IDs (input [3, 1, 2] → output [conc3, conc1, conc2])

Pass-through (~5 tests):

- fetchLocations → delegates, returns API result
- fetchSites → delegates, returns API result
- fetchPollensByLocationAndDate → delegates with correct args

Production code changes: None.

# Phase 4: ViewModels (~50 tests, 2 files + 1 helper)

test/helpers/fake_pollen_repository.dart

```dart
// ABOUTME: Configurable fake for PollenRepository used in ViewModel tests.
// ABOUTME: Overrides all methods with controllable responses and call tracking.

class FakePollenRepository extends PollenRepository {
FakePollenRepository() : super(apiService: FakePollenApiService());

List<Locations> locationsResponse = [];
List<Allergen> allergensResponse = [];
List<AllergenTypes> allergenTypesResponse = [];
List<Site> sitesResponse = [];
PaginatedResponse<Pollens>? pollensByDateResponse;
PaginatedResponse<Pollens>? recentPollensResponse;
List<Concentrations> concentrationsResponse = [];
Exception? throwOn; // set to throw from any method

@override Future<List<Locations>> fetchLocations() async { ... }
@override Future<List<Allergen>> fetchAllergens() async { ... }
// etc.
}
```

test/presentation/viewmodels/home_view_model_test.dart (~35 tests)
All tests call SharedPreferences.setMockInitialValues({}) in setUp.

Initial data loading (~3 tests):

- loadInitialData fetches locations + allergens + allergenTypes in parallel
- With saved location ID in SharedPreferences, fetchLocations restores that location
- With no saved ID, selects first location in list

Data fallback strategy (~4 tests) — feed fake repo with:

- Today's response has results → uses today's data
- Today empty, 1-year window has results → uses 1-year data
- Both empty, 2-year has results → uses 2-year data
- All empty → concentrations null, selectedDate null

Snapshot selection (~3 tests):

- Most recent pollen entry with concentrations.any(c => c.value > 0) is selected
- Skips entries with all-zero concentrations (walks backwards through dates)
- Skips entries with empty concentration IDs list

Severity counting (~4 tests) — set \_concentrations via a fake load:

- Values in [1..10] → lowCount++
- Values in [11..50] → mediumCount++
- Values >= 51 → highCount++
- Zero values not counted in any bucket

getOverallStatus / getOverallStatusColor (~4 tests):

- Any high → 'Visok', red
- Medium but no high → 'Srednji', orange
- Only low → 'Nizak', green
- All zero → 'Nema koncentracije', grey

typeDataMap computation (~6 tests):

- Groups concentrations by allergen type (1=tree, 2=grass, 3=weed)
- Skips zero-value concentrations
- Sorts by concentration \* allergenicityIndex descending
- Returns 'Nema'/'grey' for types with no positive concentrations
- Handles no allergens/concentrations (returns empty map)
- allergenId not found in allergens list → skipped

fiveTierLevel / getFiveTierColor (~3 tests):

- No site data → falls back to getOverallStatus/getOverallStatusColor
- Uses site.level max value → correct LevelHelper.levelToLabel/levelToColor
- Multiple sites → max level wins

isShowingHistoricalData (~3 tests):

- \_pollenDate null → false
- \_pollenDate = today → false
- \_pollenDate = 8 days ago → true

Error handling (~3 tests):

- error getter returns \_locationsError first when set
- error returns \_allergensError when only that is set
- Network exception from repo → wrapped as NoInternetError

Location persistence (~2 tests):

- selectLocation saves ID via SharedPreferences; second VM instance reads it back
- fetchLocations with saved ID preselects that location

test/presentation/viewmodels/map_view_model_test.dart (~15 tests)
loadLocations (~3 tests):

- Sets isLoading = true → fetches → sets isLoading = false
- On fetch error → sets error, isLoading = false
- After load, triggers \_prefetchLocationSummaries (verify cache populated via getLocationSummaryIfCached)

\_buildSummaryFromSites via getLocationSummary (~4 tests):

- Empty sites list → hasData = false, riskLabel = 'Nema podataka'
- Single site → correct level/trend mapped
- Multiple sites → maxLevel = max site.level
- Week value from sites.first.week

\_mostCommonTrend via getLocationSummary (~3 tests):

- Single site → that trend
- Two sites trend=1, one site trend=3 → trend=1 wins
- Tied counts (1 each) → higher key wins (pessimistic: trend=3 > trend=1)

Cache behavior (~3 tests):

- getLocationSummary second call returns same result, no additional repo call
- getLocationSummaryIfCached returns null before any fetch, value after
- getPinColorForLocation returns Colors.grey.shade600 for uncached, correct color for cached

refreshLocations (~2 tests):

- Clears summary cache (verified by getLocationSummaryIfCached returning null)
- Calls fetchLocations again

Production code changes: None.

# Summary

```
Phase 1: 10 files, 1 helper ~70 tests — pure logic
Phase 2: 1 file, 0 helpers ~35 tests — PollenApiService + MockClient
Phase 3: 1 file, 1 helper ~15 tests — PollenRepository + FakeApiService
Phase 4: 2 files, 1 helper ~50 tests — HomeViewModel + MapViewModel
─────────────────────────────────────────────────────────
Total: 14 files, 3 helpers ~170 tests — 0 prod changes, 0 new deps
```

Deferred: selectNearestLocationFromDevice (needs LocationService abstraction), widget tests.

# Verification

After each phase:

```bash
flutter test
flutter analyze
```

All tests green, zero analyzer warnings before proceeding to next phase.
