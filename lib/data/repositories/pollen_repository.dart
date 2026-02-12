import 'package:udahni/data/models/allergen.dart';
import 'package:udahni/data/models/allergen_types.dart';
import 'package:udahni/data/models/concentrations.dart';
import 'package:udahni/data/models/locations.dart';
import 'package:udahni/data/models/paginated_response.dart';
import 'package:udahni/data/models/pollens.dart';
import 'package:udahni/data/models/site.dart';
import 'package:udahni/data/services/pollen_api_service.dart';

class PollenRepository {
  final PollenApiService _apiService;
  final Map<int, Concentrations> _concentrationCache = {};
  final Map<int, Allergen> _allergenCache = {};

  PollenRepository({PollenApiService? apiService})
    : _apiService = apiService ?? PollenApiService();

  //--------------------------------------------------------------------------
  void dispose() {
    _apiService.dispose();
  }

  //--------------------------------------------------------------------------
  Future<List<AllergenTypes>> fetchAllergenTypes() async {
    final response = await _apiService.fetchAllergenTypes();
    return response;
  }

  //--------------------------------------------------------------------------
  Future<AllergenTypes> fetchAllergenTypeById(int id) async {
    final response = await _apiService.fetchAllergenTypeById(id);
    return response;
  }

  //--------------------------------------------------------------------------
  Future<List<Allergen>> fetchAllergens() async {
    final notCached = _allergenCache.isEmpty;
    if (!notCached) {
      return _allergenCache.values.toList();
    }

    final response = await _apiService.fetchAllergens();
    for (var allergen in response) {
      _allergenCache[allergen.id] = allergen;
    }
    return response;
  }

  //--------------------------------------------------------------------------
  Future<Allergen> fetchAllergenById(int id) async {
    final response = await _apiService.fetchAllergenById(id);
    return response;
  }

  //--------------------------------------------------------------------------
  Future<List<Locations>> fetchLocations() async {
    final response = await _apiService.fetchLocations();
    return response;
  }

  //--------------------------------------------------------------------------
  Future<Locations> fetchLocationById(int id) async {
    final response = await _apiService.fetchLocationById(id);
    return response;
  }

  //--------------------------------------------------------------------------
  Future<PaginatedResponse<Pollens>> fetchPollens({int page = 1}) async {
    final response = await _apiService.fetchPollens(page: page);
    return response;
  }

  //--------------------------------------------------------------------------
  Future<Pollens> fetchPollenById(int id) async {
    final response = await _apiService.fetchPollenById(id);
    return response;
  }

  //--------------------------------------------------------------------------
  Future<PaginatedResponse<Pollens>> fetchPollensByLocation(
    int locationId,
  ) async {
    final response = await _apiService.fetchPollensByLocation(locationId);
    return response;
  }

  //--------------------------------------------------------------------------
  Future<PaginatedResponse<Pollens>> fetchRecentPollensByLocation(
    int locationId, {
    String? dateAfter,
  }) async {
    final response = await _apiService.fetchRecentPollensByLocation(
      locationId,
      dateAfter: dateAfter,
    );
    return response;
  }

  //--------------------------------------------------------------------------
  Future<PaginatedResponse<Pollens>> fetchPollensByDate(
    String date, {
    int page = 1,
  }) async {
    final response = await _apiService.fetchPollensByDate(date, page: page);
    return response;
  }

  //--------------------------------------------------------------------------
  Future<PaginatedResponse<Pollens>> fetchPollensByLocationAndDate(
    int locationId,
    String date, {
    int page = 1,
  }) async {
    final response = await _apiService.fetchPollensByLocationAndDate(
      locationId,
      date,
      page: page,
    );
    return response;
  }

  //--------------------------------------------------------------------------
  Future<PaginatedResponse<Concentrations>> fetchConcentrations({
    int page = 1,
  }) async {
    final response = await _apiService.fetchConcentrations(page: page);
    return response;
  }

  //--------------------------------------------------------------------------
  Future<Concentrations> fetchConcentrationById(int id) async {
    final response = await _apiService.fetchConcentrationById(id);
    return response;
  }

  //--------------------------------------------------------------------------
  Future<List<Concentrations>> fetchConcentrationsByIds(List<int> ids) async {
    final notCached = ids
        .where((id) => !_concentrationCache.containsKey(id))
        .toList();

    if (notCached.isEmpty) {
      return ids.map((id) => _concentrationCache[id]!).toList();
    }

    // Fetch only missing IDs, then merge with cache.
    final uniqueNotCached = _uniqueIds(notCached);
    final newConcs = await _apiService.fetchConcentrationsByIds(
      uniqueNotCached,
    );

    for (final c in newConcs) {
      _concentrationCache[c.id] = c;
    }

    return ids.map((id) => _concentrationCache[id]!).toList();
  }

  //--------------------------------------------------------------------------
  List<int> _uniqueIds(List<int> ids) {
    final seen = <int>{};
    final result = <int>[];
    for (final id in ids) {
      if (seen.add(id)) {
        result.add(id);
      }
    }
    return result;
  }

  //--------------------------------------------------------------------------
  Future<List<Site>> fetchSites({required int locationId}) async {
    final response = await _apiService.fetchSites(locationId: locationId);
    return response;
  }
}
