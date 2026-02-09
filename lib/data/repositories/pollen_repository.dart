import 'package:alergeni/data/models/allergen.dart';
import 'package:alergeni/data/models/allergen_types.dart';
import 'package:alergeni/data/models/concentrations.dart';
import 'package:alergeni/data/models/locations.dart';
import 'package:alergeni/data/models/paginated_response.dart';
import 'package:alergeni/data/models/pollens.dart';
import 'package:alergeni/data/services/pollen_api_service.dart';

class PollenRepository {
  final PollenApiService _apiService;

  PollenRepository({PollenApiService? apiService})
    : _apiService = apiService ?? PollenApiService();

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
    final response = await _apiService.fetchAllergens();
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
    try {
      final futures = ids.map((id) => fetchConcentrationById(id));
      return Future.wait(futures);
    } catch (e) {
      throw Exception('Failed to load concentrations by IDs');
    }
  }
}
