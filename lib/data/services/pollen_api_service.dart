// ABOUTME: HTTP client for Serbia's pollen open data API with retry logic.
// ABOUTME: Handles request formatting, response parsing, and transient error recovery.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:udahni/core/config/api_config.dart';
import 'package:udahni/core/errors/app_error.dart';
import 'package:udahni/data/models/allergen.dart';
import 'package:udahni/data/models/allergen_types.dart';
import 'package:udahni/data/models/concentrations.dart';
import 'package:udahni/data/models/locations.dart';
import 'package:udahni/data/models/paginated_response.dart';
import 'package:udahni/data/models/pollens.dart';
import 'package:udahni/data/models/site.dart';

class PollenApiService {
  final http.Client _httpClient;
  final String _baseUrl;
  final bool _ownsClient;

  //--------------------------------------------------------------------------
  PollenApiService({http.Client? httpClient, String? baseUrl})
    : _httpClient = httpClient ?? http.Client(),
      _ownsClient = httpClient == null,
      _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceAll(RegExp(r'/+$'), '');

  //--------------------------------------------------------------------------
  void dispose() {
    if (_ownsClient) {
      _httpClient.close();
    }
  }

  //--------------------------------------------------------------------------
  Future<http.Response> _getWithRetry(Uri uri) async {
    final maxRetries = ApiConfig.maxRetries;

    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await _httpClient
            .get(uri)
            .timeout(ApiConfig.requestTimeout);

        if (_shouldRetryStatusCode(response.statusCode) &&
            attempt < maxRetries) {
          await Future.delayed(_retryDelay(attempt));
          continue;
        }

        return response;
      } on TimeoutException {
        if (attempt >= maxRetries) throw AppError.fromException(TimeoutException('Request to $uri timed out'));
        await Future.delayed(_retryDelay(attempt));
      } on SocketException catch (e) {
        if (attempt >= maxRetries) throw AppError.fromException(e);
        await Future.delayed(_retryDelay(attempt));
      } on http.ClientException catch (e) {
        if (attempt >= maxRetries) throw AppError.fromException(e);
        await Future.delayed(_retryDelay(attempt));
      }
    }

    throw const UnexpectedError(
      debugMessage: 'Request failed after all retry attempts',
    );
  }

  //--------------------------------------------------------------------------
  bool _shouldRetryStatusCode(int statusCode) {
    return statusCode == 408 || statusCode == 429 || statusCode >= 500;
  }

  //--------------------------------------------------------------------------
  Duration _retryDelay(int attempt) {
    const baseDelayMs = 300;
    const maxDelayMs = 4000;
    final delayMs = min(baseDelayMs * (1 << attempt), maxDelayMs);
    return Duration(milliseconds: delayMs);
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

    throw AppError.fromHttpStatus(response.statusCode);
  }

  //--------------------------------------------------------------------------
  Future<List<AllergenTypes>> fetchAllergenTypes() async {
    final response = await _getWithRetry(
      Uri.parse('$_baseUrl/allergen-types/'),
    );

    return _handleResponse<List<AllergenTypes>>(
      response,
      (json) => (json as List<dynamic>)
          .map((item) => AllergenTypes.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  //--------------------------------------------------------------------------
  Future<AllergenTypes> fetchAllergenTypeById(int id) async {
    final response = await _getWithRetry(
      Uri.parse('$_baseUrl/allergen-types/$id/'),
    );

    return _handleResponse<AllergenTypes>(
      response,
      (json) => AllergenTypes.fromJson(json as Map<String, dynamic>),
    );
  }

  //--------------------------------------------------------------------------
  Future<List<Allergen>> fetchAllergens() async {
    final response = await _getWithRetry(Uri.parse('$_baseUrl/allergens/'));

    return _handleResponse<List<Allergen>>(
      response,
      (json) => (json as List<dynamic>)
          .map((item) => Allergen.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  //--------------------------------------------------------------------------
  Future<Allergen> fetchAllergenById(int id) async {
    final response = await _getWithRetry(Uri.parse('$_baseUrl/allergens/$id/'));

    return _handleResponse<Allergen>(
      response,
      (json) => Allergen.fromJson(json as Map<String, dynamic>),
    );
  }

  //--------------------------------------------------------------------------
  Future<List<Locations>> fetchLocations() async {
    final response = await _getWithRetry(Uri.parse('$_baseUrl/locations/'));

    return _handleResponse<List<Locations>>(
      response,
      (json) => (json as List<dynamic>)
          .map((item) => Locations.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  //--------------------------------------------------------------------------
  Future<Locations> fetchLocationById(int id) async {
    final response = await _getWithRetry(Uri.parse('$_baseUrl/locations/$id/'));

    return _handleResponse<Locations>(
      response,
      (json) => Locations.fromJson(json as Map<String, dynamic>),
    );
  }

  //--------------------------------------------------------------------------
  Future<PaginatedResponse<Pollens>> fetchPollens({int page = 1}) async {
    final response = await _getWithRetry(
      Uri.parse('$_baseUrl/pollens/?page=$page'),
    );

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
    final response = await _getWithRetry(Uri.parse('$_baseUrl/pollens/$id/'));

    return _handleResponse<Pollens>(
      response,
      (json) => Pollens.fromJson(json as Map<String, dynamic>),
    );
  }

  //--------------------------------------------------------------------------
  Future<PaginatedResponse<Pollens>> fetchPollensByLocation(
    int locationId,
  ) async {
    final response = await _getWithRetry(
      Uri.parse('$_baseUrl/pollens/?location=$locationId'),
    );

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
    final response = await _getWithRetry(
      Uri.parse(
        '$_baseUrl/pollens/?location=$locationId'
        '${dateAfter != null ? '&date_after=$dateAfter' : ''}',
      ),
    );

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
    final response = await _getWithRetry(
      Uri.parse('$_baseUrl/pollens/?date=$date&page=$page'),
    );

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
    final response = await _getWithRetry(
      Uri.parse(
        '$_baseUrl/pollens/?location=$locationId&date=$date&page=$page',
      ),
    );

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
    final response = await _getWithRetry(
      Uri.parse('$_baseUrl/concentrations/?page=$page'),
    );

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
    final response = await _getWithRetry(
      Uri.parse('$_baseUrl/concentrations/$id/'),
    );

    return _handleResponse<Concentrations>(
      response,
      (json) => Concentrations.fromJson(json as Map<String, dynamic>),
    );
  }

  //--------------------------------------------------------------------------
  Future<List<Concentrations>> fetchConcentrationsByIds(List<int> ids) async {
    final uniqueIds = _uniqueIds(ids);
    if (uniqueIds.isEmpty) return [];

    final byId = <int, Concentrations>{};

    for (final uri in _batchConcentrationUris(uniqueIds)) {
      try {
        final response = await _getWithRetry(uri);
        final fetched = await _handleResponse<List<Concentrations>>(
          response,
          _parseConcentrationsCollection,
        );
        for (final concentration in fetched) {
          if (uniqueIds.contains(concentration.id)) {
            byId[concentration.id] = concentration;
          }
        }
        if (byId.length == uniqueIds.length) {
          break;
        }
      } catch (_) {
        // Fall back to per-id fetch below when batch query style is unsupported.
      }
    }

    final missingIds = uniqueIds.where((id) => !byId.containsKey(id)).toList();
    if (missingIds.isNotEmpty) {
      final fallbackFetched = await _fetchConcentrationsByIdsChunked(
        missingIds,
      );
      for (final concentration in fallbackFetched) {
        byId[concentration.id] = concentration;
      }
    }

    final unresolved = uniqueIds.where((id) => !byId.containsKey(id)).toList();
    if (unresolved.isNotEmpty) {
      throw Exception('Failed to load concentrations for ids: $unresolved');
    }

    return uniqueIds.map((id) => byId[id]!).toList();
  }

  //--------------------------------------------------------------------------
  List<Concentrations> _parseConcentrationsCollection(dynamic json) {
    if (json is Map<String, dynamic> && json['results'] is List<dynamic>) {
      return (json['results'] as List<dynamic>)
          .map((item) => Concentrations.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    if (json is List<dynamic>) {
      return json
          .map((item) => Concentrations.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Unexpected concentrations response format');
  }

  //--------------------------------------------------------------------------
  List<Uri> _batchConcentrationUris(List<int> ids) {
    final joined = ids.join(',');
    final repeatedIdParams = ids.map((id) => 'id=$id').join('&');

    return [
      Uri.parse('$_baseUrl/concentrations/?id__in=$joined'),
      Uri.parse('$_baseUrl/concentrations/?$repeatedIdParams'),
    ];
  }

  //--------------------------------------------------------------------------
  Future<List<Concentrations>> _fetchConcentrationsByIdsChunked(
    List<int> ids,
  ) async {
    const chunkSize = 6;
    final results = <Concentrations>[];

    for (var i = 0; i < ids.length; i += chunkSize) {
      final end = min(i + chunkSize, ids.length);
      final chunk = ids.sublist(i, end);
      final chunkResults = await Future.wait(
        chunk.map((id) => fetchConcentrationById(id)),
      );
      results.addAll(chunkResults);
    }

    return results;
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
    final baseWithoutOpenData = _baseUrl.replaceFirst(
      RegExp(r'/opendata$'),
      '',
    );

    final uri = Uri.parse('$baseWithoutOpenData/site/$locationId/');

    final response = await _getWithRetry(uri);
    return _handleResponse<List<Site>>(
      response,
      (json) => (json as List<dynamic>)
          .map((item) => Site.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
