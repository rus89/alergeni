// ABOUTME: Hand-written fake for PollenApiService for use in repository and ViewModel tests.
// ABOUTME: Tracks call counts per method and returns configurable data.

import 'package:http/testing.dart';
import 'package:udahni/data/models/allergen.dart';
import 'package:udahni/data/models/allergen_types.dart';
import 'package:udahni/data/models/concentrations.dart';
import 'package:udahni/data/models/locations.dart';
import 'package:udahni/data/models/paginated_response.dart';
import 'package:udahni/data/models/pollens.dart';
import 'package:udahni/data/models/site.dart';
import 'package:udahni/data/services/pollen_api_service.dart';

class FakePollenApiService extends PollenApiService {
  // Configurable return values
  List<Allergen> allergensResult = [];
  List<AllergenTypes> allergenTypesResult = [];
  List<Locations> locationsResult = [];
  List<Concentrations> concentrationsByIdsResult = [];
  List<Site> sitesResult = [];
  PaginatedResponse<Pollens> pollensResult = PaginatedResponse(
    count: 0,
    next: null,
    previous: null,
    results: [],
  );

  // Call tracking
  int fetchAllergensCallCount = 0;
  int fetchConcentrationsByIdsCallCount = 0;
  int fetchLocationsCallCount = 0;
  int fetchSitesCallCount = 0;
  List<List<int>> fetchConcentrationsByIdsArgs = [];

  // Error injection
  Object? allergensFetchError;
  Object? concentrationsFetchError;
  Object? locationsFetchError;
  Object? sitesFetchError;
  Object? pollensFetchError;

  FakePollenApiService()
      : super(
          // Throw if real HTTP is ever called accidentally
          httpClient: MockClient((_) async => throw AssertionError(
                'FakePollenApiService should not make real HTTP calls',
              )),
          baseUrl: 'http://fake',
        );

  @override
  Future<List<Allergen>> fetchAllergens() async {
    fetchAllergensCallCount++;
    if (allergensFetchError != null) throw allergensFetchError!;
    return List.of(allergensResult);
  }

  @override
  Future<List<AllergenTypes>> fetchAllergenTypes() async {
    if (allergensFetchError != null) throw allergensFetchError!;
    return List.of(allergenTypesResult);
  }

  @override
  Future<List<Locations>> fetchLocations() async {
    fetchLocationsCallCount++;
    if (locationsFetchError != null) throw locationsFetchError!;
    return List.of(locationsResult);
  }

  @override
  Future<List<Concentrations>> fetchConcentrationsByIds(List<int> ids) async {
    fetchConcentrationsByIdsCallCount++;
    fetchConcentrationsByIdsArgs.add(List.of(ids));
    if (concentrationsFetchError != null) throw concentrationsFetchError!;
    return List.of(concentrationsByIdsResult);
  }

  @override
  Future<List<Site>> fetchSites({required int locationId}) async {
    fetchSitesCallCount++;
    if (sitesFetchError != null) throw sitesFetchError!;
    return List.of(sitesResult);
  }

  @override
  Future<PaginatedResponse<Pollens>> fetchPollensByLocationAndDate(
    int locationId,
    String date, {
    int page = 1,
  }) async {
    if (pollensFetchError != null) throw pollensFetchError!;
    return pollensResult;
  }

  @override
  Future<PaginatedResponse<Pollens>> fetchRecentPollensByLocation(
    int locationId, {
    String? dateAfter,
  }) async {
    if (pollensFetchError != null) throw pollensFetchError!;
    return pollensResult;
  }

  @override
  void dispose() {
    // Nothing to dispose in the fake
  }
}
