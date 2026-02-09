import 'dart:convert';

import 'package:alergeni/data/models/allergen.dart';
import 'package:alergeni/data/models/allergen_types.dart';
import 'package:alergeni/data/models/concentrations.dart';
import 'package:alergeni/data/models/locations.dart';
import 'package:alergeni/data/models/paginated_response.dart';
import 'package:alergeni/data/models/pollens.dart';
import 'package:http/http.dart' as http;

class PollenApiService {
  static const String _defaultBaseUrl = 'http://77.46.150.200/api/opendata';
  static const _requestTimeout = Duration(seconds: 10);

  final http.Client _httpClient;
  final String _baseUrl;
  final bool _ownsClient;

  //--------------------------------------------------------------------------
  PollenApiService({http.Client? httpClient, String? baseUrl})
    : _httpClient = httpClient ?? http.Client(),
      _ownsClient = httpClient == null,
      _baseUrl = (baseUrl ?? _defaultBaseUrl).replaceAll(RegExp(r'/+$'), '');

  //--------------------------------------------------------------------------
  void dispose() {
    if (_ownsClient) {
      _httpClient.close();
    }
  }

  //--------------------------------------------------------------------------
  Future<R> _handleResponse<R>(
    http.Response response,
    R Function(dynamic json) parser,
  ) async {
    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      return parser(decoded);
    }

    final payloadSnippet = response.body.length > 200
        ? '${response.body.substring(0, 200)}…'
        : response.body;

    final message = response.statusCode >= 500
        ? 'Server error'
        : response.statusCode >= 400
        ? 'Client error'
        : 'Unexpected status';

    throw Exception(
      '$message ${response.statusCode} (${response.reasonPhrase ?? 'no reason'}) – $payloadSnippet',
    );
  }

  //--------------------------------------------------------------------------
  Future<List<AllergenTypes>> fetchAllergenTypes() async {
    final response = await _httpClient
        .get(Uri.parse('$_baseUrl/allergen-types/'))
        .timeout(_requestTimeout);

    return _handleResponse<List<AllergenTypes>>(
      response,
      (json) => (json as List<dynamic>)
          .map((item) => AllergenTypes.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  //--------------------------------------------------------------------------
  Future<AllergenTypes> fetchAllergenTypeById(int id) async {
    final response = await _httpClient
        .get(Uri.parse('$_baseUrl/allergen-types/$id/'))
        .timeout(_requestTimeout);

    return _handleResponse<AllergenTypes>(
      response,
      (json) => AllergenTypes.fromJson(json as Map<String, dynamic>),
    );
  }

  //--------------------------------------------------------------------------
  Future<List<Allergen>> fetchAllergens() async {
    final response = await _httpClient
        .get(Uri.parse('$_baseUrl/allergens/'))
        .timeout(_requestTimeout);

    return _handleResponse<List<Allergen>>(
      response,
      (json) => (json as List<dynamic>)
          .map((item) => Allergen.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  //--------------------------------------------------------------------------
  Future<Allergen> fetchAllergenById(int id) async {
    final response = await _httpClient
        .get(Uri.parse('$_baseUrl/allergens/$id/'))
        .timeout(_requestTimeout);

    return _handleResponse<Allergen>(
      response,
      (json) => Allergen.fromJson(json as Map<String, dynamic>),
    );
  }

  //--------------------------------------------------------------------------
  Future<List<Locations>> fetchLocations() async {
    final response = await _httpClient
        .get(Uri.parse('$_baseUrl/locations/'))
        .timeout(_requestTimeout);

    return _handleResponse<List<Locations>>(
      response,
      (json) => (json as List<dynamic>)
          .map((item) => Locations.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  //--------------------------------------------------------------------------
  Future<Locations> fetchLocationById(int id) async {
    final response = await _httpClient
        .get(Uri.parse('$_baseUrl/locations/$id/'))
        .timeout(_requestTimeout);

    return _handleResponse<Locations>(
      response,
      (json) => Locations.fromJson(json as Map<String, dynamic>),
    );
  }

  //--------------------------------------------------------------------------
  Future<PaginatedResponse<Pollens>> fetchPollens({int page = 1}) async {
    final response = await _httpClient
        .get(Uri.parse('$_baseUrl/pollens/?page=$page'))
        .timeout(_requestTimeout);

    return _handleResponse<PaginatedResponse<Pollens>>(
      response,
      (json) => PaginatedResponse<Pollens>.fromJson(
        json as Map<String, dynamic>,
        (json) => Pollens.fromJson(json),
      ),
    );
  }

  //--------------------------------------------------------------------------
  Future<Pollens> fetchPollenById(int id) async {
    final response = await _httpClient
        .get(Uri.parse('$_baseUrl/pollens/$id/'))
        .timeout(_requestTimeout);

    return _handleResponse<Pollens>(
      response,
      (json) => Pollens.fromJson(json as Map<String, dynamic>),
    );
  }

  //--------------------------------------------------------------------------
  Future<PaginatedResponse<Pollens>> fetchPollensByLocation(
    int locationId,
  ) async {
    final response = await _httpClient
        .get(Uri.parse('$_baseUrl/pollens/?location=$locationId'))
        .timeout(_requestTimeout);

    return _handleResponse<PaginatedResponse<Pollens>>(
      response,
      (json) => PaginatedResponse<Pollens>.fromJson(
        json as Map<String, dynamic>,
        (json) => Pollens.fromJson(json),
      ),
    );
  }

  //--------------------------------------------------------------------------
  Future<PaginatedResponse<Pollens>> fetchRecentPollensByLocation(
    int locationId, {
    String? dateAfter,
  }) async {
    final response = await _httpClient
        .get(
          Uri.parse(
            '$_baseUrl/pollens/?location=$locationId'
            '${dateAfter != null ? '&date_after=$dateAfter' : ''}',
          ),
        )
        .timeout(_requestTimeout);

    return _handleResponse<PaginatedResponse<Pollens>>(
      response,
      (json) => PaginatedResponse<Pollens>.fromJson(
        json as Map<String, dynamic>,
        (json) => Pollens.fromJson(json),
      ),
    );
  }

  //--------------------------------------------------------------------------
  Future<PaginatedResponse<Pollens>> fetchPollensByDate(
    String date, {
    int page = 1,
  }) async {
    final response = await _httpClient
        .get(Uri.parse('$_baseUrl/pollens/?date=$date&page=$page'))
        .timeout(_requestTimeout);

    return _handleResponse<PaginatedResponse<Pollens>>(
      response,
      (json) => PaginatedResponse<Pollens>.fromJson(
        json as Map<String, dynamic>,
        (json) => Pollens.fromJson(json),
      ),
    );
  }

  //--------------------------------------------------------------------------
  Future<PaginatedResponse<Pollens>> fetchPollensByLocationAndDate(
    int locationId,
    String date, {
    int page = 1,
  }) async {
    final response = await _httpClient
        .get(
          Uri.parse(
            '$_baseUrl/pollens/?location=$locationId&date=$date&page=$page',
          ),
        )
        .timeout(_requestTimeout);

    return _handleResponse<PaginatedResponse<Pollens>>(
      response,
      (json) => PaginatedResponse<Pollens>.fromJson(
        json as Map<String, dynamic>,
        (json) => Pollens.fromJson(json),
      ),
    );
  }

  //--------------------------------------------------------------------------
  Future<PaginatedResponse<Concentrations>> fetchConcentrations({
    int page = 1,
  }) async {
    final response = await _httpClient
        .get(Uri.parse('$_baseUrl/concentrations/?page=$page'))
        .timeout(_requestTimeout);

    return _handleResponse<PaginatedResponse<Concentrations>>(
      response,
      (json) => PaginatedResponse<Concentrations>.fromJson(
        json as Map<String, dynamic>,
        (json) => Concentrations.fromJson(json),
      ),
    );
  }

  //--------------------------------------------------------------------------
  Future<Concentrations> fetchConcentrationById(int id) async {
    final response = await _httpClient
        .get(Uri.parse('$_baseUrl/concentrations/$id/'))
        .timeout(_requestTimeout);

    return _handleResponse<Concentrations>(
      response,
      (json) => Concentrations.fromJson(json as Map<String, dynamic>),
    );
  }

  //--------------------------------------------------------------------------
  Future<List<Concentrations>> fetchConcentrationsByIds(List<int> ids) async {
    try {
      final futures = ids.map((id) => fetchConcentrationById(id));
      return Future.wait(futures);
    } catch (e) {
      throw Exception('Failed to load concentrations for ids: $ids. Error: $e');
    }
  }
}
