import 'dart:convert';
import 'package:alergeni/data/models/allergen.dart';
import 'package:alergeni/data/models/concentrations.dart';
import 'package:alergeni/data/models/locations.dart';
import 'package:alergeni/data/models/paginated_response.dart';
import 'package:alergeni/data/models/pollens.dart';
import 'package:http/http.dart' as http;
import 'package:alergeni/data/models/allergen_types.dart';

class PollenRepository {
  static const String _baseUrl = 'http://77.46.150.200/api/opendata';

  //--------------------------------------------------------------------------
  Future<List<AllergenTypes>> fetchAllergenTypes() async {
    final response = await http.get(Uri.parse('$_baseUrl/allergen-types/'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((json) => AllergenTypes.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load allergen types');
    }
  }

  //--------------------------------------------------------------------------
  Future<AllergenTypes> fetchAllergenTypeById(int id) async {
    final response = await http.get(Uri.parse('$_baseUrl/allergen-types/$id/'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return AllergenTypes.fromJson(data);
    } else {
      throw Exception('Failed to load allergen type');
    }
  }

  //--------------------------------------------------------------------------
  Future<List<Allergen>> fetchAllergens() async {
    final response = await http.get(Uri.parse('$_baseUrl/allergens/'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((json) => Allergen.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load allergens');
    }
  }

  //--------------------------------------------------------------------------
  Future<Allergen> fetchAllergenById(int id) async {
    final response = await http.get(Uri.parse('$_baseUrl/allergens/$id/'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return Allergen.fromJson(data);
    } else {
      throw Exception('Failed to load allergen');
    }
  }

  //--------------------------------------------------------------------------
  Future<List<Locations>> fetchLocations() async {
    final response = await http.get(Uri.parse('$_baseUrl/locations/'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((json) => Locations.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load locations');
    }
  }

  //--------------------------------------------------------------------------
  Future<Locations> fetchLocationById(int id) async {
    final response = await http.get(Uri.parse('$_baseUrl/locations/$id/'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return Locations.fromJson(data);
    } else {
      throw Exception('Failed to load location');
    }
  }

  //--------------------------------------------------------------------------
  Future<PaginatedResponse<Pollens>> fetchPollens({int page = 1}) async {
    final response = await http.get(Uri.parse('$_baseUrl/pollens/?page=$page'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return PaginatedResponse<Pollens>.fromJson(
        data,
        (json) => Pollens.fromJson(json),
      );
    } else {
      throw Exception('Failed to load pollens');
    }
  }

  //--------------------------------------------------------------------------
  Future<Pollens> fetchPollenById(int id) async {
    final response = await http.get(Uri.parse('$_baseUrl/pollens/$id/'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return Pollens.fromJson(data);
    } else {
      throw Exception('Failed to load pollen');
    }
  }

  //--------------------------------------------------------------------------
  Future<PaginatedResponse<Pollens>> fetchPollensByLocation(
    int locationId,
  ) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/pollens/?location=$locationId'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return PaginatedResponse.fromJson(data, Pollens.fromJson);
    } else {
      throw Exception('Failed to load pollens for location $locationId');
    }
  }

  //--------------------------------------------------------------------------
  Future<PaginatedResponse<Pollens>> fetchRecentPollensByLocation(
    int locationId, {
    String? dateAfter,
  }) async {
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/pollens/?location=$locationId'
        '${dateAfter != null ? '&date_after=$dateAfter' : ''}',
      ),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return PaginatedResponse.fromJson(data, Pollens.fromJson);
    } else {
      throw Exception('Failed to load recent pollens for location $locationId');
    }
  }

  //--------------------------------------------------------------------------
  Future<PaginatedResponse<Pollens>> fetchPollensByDate(
    String date, {
    int page = 1,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/pollens/?date=$date&page=$page'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return PaginatedResponse.fromJson(data, Pollens.fromJson);
    } else {
      throw Exception('Failed to load pollens for date $date');
    }
  }

  //--------------------------------------------------------------------------
  Future<PaginatedResponse<Pollens>> fetchPollensByLocationAndDate(
    int locationId,
    String date, {
    int page = 1,
  }) async {
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/pollens/?location=$locationId&date=$date&page=$page',
      ),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return PaginatedResponse.fromJson(data, Pollens.fromJson);
    } else {
      throw Exception(
        'Failed to load pollens for location $locationId and date $date',
      );
    }
  }

  //--------------------------------------------------------------------------
  Future<PaginatedResponse<Concentrations>> fetchConcentrations({
    int page = 1,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/concentrations/?page=$page'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return PaginatedResponse.fromJson(data, Concentrations.fromJson);
    } else {
      throw Exception('Failed to load concentrations');
    }
  }

  //--------------------------------------------------------------------------
  Future<Concentrations> fetchConcentrationById(int id) async {
    final response = await http.get(Uri.parse('$_baseUrl/concentrations/$id/'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return Concentrations.fromJson(data);
    } else {
      throw Exception('Failed to load concentration');
    }
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
