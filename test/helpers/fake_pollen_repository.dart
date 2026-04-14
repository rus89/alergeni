// ABOUTME: Hand-written fake for PollenRepository for use in ViewModel tests.
// ABOUTME: Overrides all methods called by ViewModels with configurable data and call tracking.

import 'package:udahni/data/models/allergen.dart';
import 'package:udahni/data/models/allergen_types.dart';
import 'package:udahni/data/models/concentrations.dart';
import 'package:udahni/data/models/locations.dart';
import 'package:udahni/data/models/paginated_response.dart';
import 'package:udahni/data/models/pollens.dart';
import 'package:udahni/data/models/site.dart';
import 'package:udahni/data/repositories/pollen_repository.dart';

import 'fake_pollen_api_service.dart';

class FakePollenRepository extends PollenRepository {
  // Configurable return values
  List<Locations> locationsResult = [];
  List<Allergen> allergensResult = [];
  List<AllergenTypes> allergenTypesResult = [];
  PaginatedResponse<Pollens> pollensByLocationAndDateResult = _emptyPollens;
  // Consumed in order; falls back to recentPollensByLocationResult when empty.
  final List<PaginatedResponse<Pollens>> recentPollensQueue = [];
  PaginatedResponse<Pollens> recentPollensByLocationResult = _emptyPollens;
  List<Concentrations> concentrationsByIdsResult = [];
  List<Site> sitesResult = [];

  // Error injection
  Object? locationsError;
  Object? allergensError;
  Object? sitesError;

  // Call tracking
  int fetchLocationsCallCount = 0;
  int fetchSitesCallCount = 0;
  int recentPollensByLocationCallCount = 0;
  final List<String?> recentPollensByLocationDateAfterArgs = [];

  FakePollenRepository() : super(apiService: FakePollenApiService());

  @override
  Future<List<Locations>> fetchLocations() async {
    fetchLocationsCallCount++;
    if (locationsError != null) throw locationsError!;
    return List.of(locationsResult);
  }

  @override
  Future<List<Allergen>> fetchAllergens() async {
    if (allergensError != null) throw allergensError!;
    return List.of(allergensResult);
  }

  @override
  Future<List<AllergenTypes>> fetchAllergenTypes() async {
    return List.of(allergenTypesResult);
  }

  @override
  Future<PaginatedResponse<Pollens>> fetchPollensByLocationAndDate(
    int locationId,
    String date, {
    int page = 1,
  }) async {
    return pollensByLocationAndDateResult;
  }

  @override
  Future<PaginatedResponse<Pollens>> fetchRecentPollensByLocation(
    int locationId, {
    String? dateAfter,
  }) async {
    recentPollensByLocationCallCount++;
    recentPollensByLocationDateAfterArgs.add(dateAfter);
    if (recentPollensQueue.isNotEmpty) {
      return recentPollensQueue.removeAt(0);
    }
    return recentPollensByLocationResult;
  }

  @override
  Future<List<Concentrations>> fetchConcentrationsByIds(List<int> ids) async {
    return List.of(concentrationsByIdsResult);
  }

  @override
  Future<List<Site>> fetchSites({required int locationId}) async {
    fetchSitesCallCount++;
    if (sitesError != null) throw sitesError!;
    return List.of(sitesResult);
  }

  static final _emptyPollens = PaginatedResponse<Pollens>(
    count: 0,
    next: null,
    previous: null,
    results: [],
  );
}
