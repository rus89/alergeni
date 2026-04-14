// ABOUTME: Tests for PollenApiService HTTP layer: retry logic, error handling, URL construction.
// ABOUTME: Uses MockClient from http/testing.dart injected via the constructor.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:udahni/core/errors/app_error.dart';
import 'package:udahni/data/models/allergen.dart';
import 'package:udahni/data/services/pollen_api_service.dart';

const _base = 'http://test/api/opendata';

// Returns a service backed by a MockClient that responds with the given handler.
PollenApiService _service(
  Future<http.Response> Function(http.Request) handler,
) {
  return PollenApiService(
    httpClient: MockClient(handler),
    baseUrl: _base,
  );
}

// Builds a 200 response with a JSON body.
http.Response _ok(Object body) =>
    http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'});

// Builds a response with the given status code and empty body.
http.Response _status(int code) => http.Response('', code);

// Allergen JSON fixture.
Map<String, dynamic> _allergenJson({int id = 1}) => {
      'id': id,
      'name': 'Betula',
      'localized_name': 'Breza',
      'margine_top': 0,
      'margine_bottom': 0,
      'type': 1,
      'allergenicity': 2,
      'allergenicity_display': 'moderate',
    };

// Concentration JSON fixture.
Map<String, dynamic> _concentrationJson({int id = 1, int allergenId = 1, int value = 10}) => {
      'id': id,
      'allergen': allergenId,
      'value': value,
      'pollen': 1,
    };

void main() {
  group('_getWithRetry — retry behavior', () {
    test('succeeds on first attempt with 200', () async {
      var callCount = 0;
      final service = _service((req) async {
        callCount++;
        return _ok([_allergenJson()]);
      });

      await service.fetchAllergens();
      expect(callCount, 1);
    });

    test('retries on 500 and succeeds on second attempt', () {
      fakeAsync((async) {
        var callCount = 0;
        final service = _service((req) async {
          callCount++;
          return callCount == 1 ? _status(500) : _ok([_allergenJson()]);
        });

        List<Allergen>? result;
        service.fetchAllergens().then((r) => result = r);

        // Advance past first retry delay (attempt=0 → 300 ms)
        async.elapse(const Duration(milliseconds: 400));

        expect(callCount, 2);
        expect(result, isNotNull);
        expect(result!.length, 1);
      });
    });

    test('retries on 408', () {
      fakeAsync((async) {
        var callCount = 0;
        final service = _service((req) async {
          callCount++;
          return callCount < 3 ? _status(408) : _ok([_allergenJson()]);
        });

        List<Allergen>? result;
        service.fetchAllergens().then((r) => result = r);

        // Advance past two retry delays (attempt=0: 300 ms, attempt=1: 600 ms → total 900 ms)
        async.elapse(const Duration(milliseconds: 1000));

        expect(callCount, 3);
        expect(result, isNotNull);
      });
    });

    test('retries on 429', () {
      fakeAsync((async) {
        var callCount = 0;
        final service = _service((req) async {
          callCount++;
          return callCount < 2 ? _status(429) : _ok([_allergenJson()]);
        });

        List<Allergen>? result;
        service.fetchAllergens().then((r) => result = r);

        // Advance past first retry delay (attempt=0 → 300 ms)
        async.elapse(const Duration(milliseconds: 400));

        expect(callCount, 2);
        expect(result, isNotNull);
      });
    });

    test('does not retry on 400', () async {
      var callCount = 0;
      final service = _service((req) async {
        callCount++;
        return _status(400);
      });

      await expectLater(service.fetchAllergens(), throwsA(isA<UnexpectedError>()));
      expect(callCount, 1);
    });

    test('does not retry on 404', () async {
      var callCount = 0;
      final service = _service((req) async {
        callCount++;
        return _status(404);
      });

      await expectLater(service.fetchAllergens(), throwsA(isA<NotFoundError>()));
      expect(callCount, 1);
    });

    test('throws NoInternetError after exhausting retries on SocketException', () {
      fakeAsync((async) {
        var callCount = 0;
        final service = _service((req) async {
          callCount++;
          throw const SocketException('No route to host');
        });

        Object? caught;
        service.fetchAllergens().catchError((Object e) {
          caught = e;
          return <Allergen>[];
        });

        // maxRetries=3 → 4 total attempts, delays: 300 ms + 600 ms + 1200 ms = 2100 ms
        async.elapse(const Duration(milliseconds: 2500));

        expect(callCount, 4);
        expect(caught, isA<NoInternetError>());
      });
    });

    test('throws NoInternetError after exhausting retries on TimeoutException', () {
      fakeAsync((async) {
        var callCount = 0;
        final service = _service((req) async {
          callCount++;
          throw TimeoutException('Request timed out');
        });

        Object? caught;
        service.fetchAllergens().catchError((Object e) {
          caught = e;
          return <Allergen>[];
        });

        async.elapse(const Duration(milliseconds: 2500));

        expect(callCount, 4);
        expect(caught, isA<NoInternetError>());
      });
    });

    test('throws ServerError after exhausting retries on 500', () {
      fakeAsync((async) {
        var callCount = 0;
        final service = _service((req) async {
          callCount++;
          return _status(500);
        });

        Object? caught;
        service.fetchAllergens().catchError((Object e) {
          caught = e;
          return <Allergen>[];
        });

        async.elapse(const Duration(milliseconds: 2500));

        expect(callCount, 4);
        expect(caught, isA<ServerError>());
      });
    });

    test('throws NoInternetError after exhausting retries on ClientException', () {
      fakeAsync((async) {
        var callCount = 0;
        final service = _service((req) async {
          callCount++;
          throw http.ClientException('Connection reset');
        });

        Object? caught;
        service.fetchAllergens().catchError((Object e) {
          caught = e;
          return <Allergen>[];
        });

        async.elapse(const Duration(milliseconds: 2500));

        expect(callCount, 4);
        expect(caught, isA<NoInternetError>());
      });
    });
  });

  group('_handleResponse — HTTP status to AppError mapping', () {
    test('200 returns parsed result', () async {
      final service = _service((_) async => _ok([_allergenJson()]));
      final result = await service.fetchAllergens();
      expect(result.length, 1);
      expect(result.first.name, 'Betula');
    });

    test('500 throws ServerError', () {
      fakeAsync((async) {
        Object? caught;
        _service((_) async => _status(500))
            .fetchAllergens()
            .catchError((Object e) { caught = e; return <Allergen>[]; });
        async.elapse(const Duration(milliseconds: 2500));
        expect(caught, isA<ServerError>());
      });
    });

    test('503 throws ServerError', () {
      fakeAsync((async) {
        Object? caught;
        _service((_) async => _status(503))
            .fetchAllergens()
            .catchError((Object e) { caught = e; return <Allergen>[]; });
        async.elapse(const Duration(milliseconds: 2500));
        expect(caught, isA<ServerError>());
      });
    });

    test('404 throws NotFoundError', () async {
      final service = _service((_) async => _status(404));
      await expectLater(service.fetchAllergens(), throwsA(isA<NotFoundError>()));
    });

    test('400 throws UnexpectedError', () async {
      final service = _service((_) async => _status(400));
      await expectLater(service.fetchAllergens(), throwsA(isA<UnexpectedError>()));
    });

    test('malformed JSON on 200 throws', () async {
      final service = _service((_) async => http.Response('not valid json {{', 200));
      await expectLater(service.fetchAllergens(), throwsA(anything));
    });
  });

  group('URL construction', () {
    test('fetchAllergenTypes hits /allergen-types/', () async {
      Uri? capturedUri;
      final service = _service((req) async {
        capturedUri = req.url;
        return _ok(<dynamic>[]);
      });

      await service.fetchAllergenTypes();
      expect(capturedUri?.path, endsWith('/allergen-types/'));
    });

    test('fetchAllergens hits /allergens/', () async {
      Uri? capturedUri;
      final service = _service((req) async {
        capturedUri = req.url;
        return _ok(<dynamic>[]);
      });

      await service.fetchAllergens();
      expect(capturedUri?.path, endsWith('/allergens/'));
    });

    test('fetchLocations hits /locations/', () async {
      Uri? capturedUri;
      final service = _service((req) async {
        capturedUri = req.url;
        return _ok(<dynamic>[]);
      });

      await service.fetchLocations();
      expect(capturedUri?.path, endsWith('/locations/'));
    });

    test('fetchPollensByLocationAndDate constructs correct query string', () async {
      Uri? capturedUri;
      final service = _service((req) async {
        capturedUri = req.url;
        return _ok({'count': 0, 'next': null, 'previous': null, 'results': <dynamic>[]});
      });

      await service.fetchPollensByLocationAndDate(5, '2026-04-01');
      expect(capturedUri?.queryParameters['location'], '5');
      expect(capturedUri?.queryParameters['date'], '2026-04-01');
      expect(capturedUri?.queryParameters['page'], '1');
    });

    test('fetchRecentPollensByLocation includes date_after when provided', () async {
      Uri? capturedUri;
      final service = _service((req) async {
        capturedUri = req.url;
        return _ok({'count': 0, 'next': null, 'previous': null, 'results': <dynamic>[]});
      });

      await service.fetchRecentPollensByLocation(3, dateAfter: '2025-01-01');
      expect(capturedUri?.queryParameters['location'], '3');
      expect(capturedUri?.queryParameters['date_after'], '2025-01-01');
    });

    test('fetchRecentPollensByLocation omits date_after when null', () async {
      Uri? capturedUri;
      final service = _service((req) async {
        capturedUri = req.url;
        return _ok({'count': 0, 'next': null, 'previous': null, 'results': <dynamic>[]});
      });

      await service.fetchRecentPollensByLocation(3);
      expect(capturedUri?.queryParameters.containsKey('date_after'), isFalse);
    });

    test('fetchSites strips /opendata and hits /site/{id}/', () async {
      Uri? capturedUri;
      final service = _service((req) async {
        capturedUri = req.url;
        return _ok(<dynamic>[]);
      });

      await service.fetchSites(locationId: 7);
      expect(capturedUri?.path, endsWith('/site/7/'));
      expect(capturedUri?.path, isNot(contains('/opendata/')));
    });

    test('fetchPollens includes page parameter', () async {
      Uri? capturedUri;
      final service = _service((req) async {
        capturedUri = req.url;
        return _ok({'count': 0, 'next': null, 'previous': null, 'results': <dynamic>[]});
      });

      await service.fetchPollens(page: 3);
      expect(capturedUri?.queryParameters['page'], '3');
    });
  });

  group('fetchConcentrationsByIds — three-strategy fallback', () {
    test('returns empty list for empty input', () async {
      final service = _service((_) async => throw AssertionError('should not be called'));
      final result = await service.fetchConcentrationsByIds([]);
      expect(result, isEmpty);
    });

    test('deduplicates input IDs', () async {
      final requests = <Uri>[];
      final service = _service((req) async {
        requests.add(req.url);
        return _ok([_concentrationJson(id: 1)]);
      });

      final result = await service.fetchConcentrationsByIds([1, 1, 1]);
      expect(result.length, 1);
      // Only one network call needed (batch strategy 1 resolved all)
      expect(requests.length, 1);
    });

    test('strategy 1 (id__in) succeeds and returns all concentrations', () async {
      final requests = <Uri>[];
      final service = _service((req) async {
        requests.add(req.url);
        if (req.url.queryParameters.containsKey('id__in')) {
          return _ok([
            _concentrationJson(id: 1),
            _concentrationJson(id: 2),
          ]);
        }
        return _ok(<dynamic>[]);
      });

      final result = await service.fetchConcentrationsByIds([1, 2]);
      expect(result.length, 2);
      // Only one call needed — first batch strategy worked
      expect(requests.where((u) => u.queryParameters.containsKey('id__in')).length, 1);
    });

    test('strategy 2 (repeated id=) is tried when strategy 1 fails', () async {
      final requests = <Uri>[];
      final service = _service((req) async {
        requests.add(req.url);
        if (req.url.queryParameters.containsKey('id__in')) {
          // Strategy 1 returns empty (server doesn't support id__in)
          return _ok(<dynamic>[]);
        }
        // Strategy 2 returns data
        return _ok([
          _concentrationJson(id: 1),
          _concentrationJson(id: 2),
        ]);
      });

      final result = await service.fetchConcentrationsByIds([1, 2]);
      expect(result.length, 2);
    });

    test('falls back to per-id chunked fetch when both batch strategies fail', () async {
      final requests = <Uri>[];
      final service = _service((req) async {
        requests.add(req.url);
        if (req.url.queryParameters.containsKey('id__in') ||
            req.url.queryParameters.containsKey('id')) {
          // Both batch strategies return empty
          return _ok(<dynamic>[]);
        }
        // Per-id fetch (e.g. /concentrations/1/) succeeds
        // pathSegments has trailing empty string for URLs ending in '/'
        final segments = req.url.pathSegments.where((s) => s.isNotEmpty).toList();
        final id = int.parse(segments.last);
        return _ok(_concentrationJson(id: id));
      });

      final result = await service.fetchConcentrationsByIds([1, 2]);
      expect(result.length, 2);
      expect(result.map((c) => c.id).toSet(), {1, 2});
    });

    test('handles paginated response format with results key', () async {
      final service = _service((req) async {
        if (req.url.queryParameters.containsKey('id__in')) {
          return _ok({
            'count': 1,
            'next': null,
            'previous': null,
            'results': [_concentrationJson(id: 1)],
          });
        }
        return _ok(<dynamic>[]);
      });

      final result = await service.fetchConcentrationsByIds([1]);
      expect(result.length, 1);
      expect(result.first.id, 1);
    });

    test('returns results in input order', () async {
      final service = _service((req) async {
        return _ok([
          _concentrationJson(id: 3),
          _concentrationJson(id: 1),
          _concentrationJson(id: 2),
        ]);
      });

      final result = await service.fetchConcentrationsByIds([1, 2, 3]);
      expect(result.map((c) => c.id).toList(), [1, 2, 3]);
    });
  });

  group('response parsing', () {
    test('fetchAllergens parses list of allergens', () async {
      final service = _service((_) async => _ok([
            _allergenJson(id: 1),
            _allergenJson(id: 2),
          ]));

      final result = await service.fetchAllergens();
      expect(result.length, 2);
      expect(result[0].id, 1);
      expect(result[1].id, 2);
    });

    test('fetchPollens parses PaginatedResponse', () async {
      final service = _service((_) async => _ok({
            'count': 1,
            'next': null,
            'previous': null,
            'results': [
              {
                'id': 1,
                'location': 2,
                'date': '2026-04-01',
                'concentrations': [10, 20],
              }
            ],
          }));

      final result = await service.fetchPollens();
      expect(result.count, 1);
      expect(result.results.length, 1);
      expect(result.results.first.locationId, 2);
    });

    test('fetchSites parses list of site entries', () async {
      final service = _service((_) async => _ok([
            {
              'location': 1,
              'date': '2026-04-01',
              'allergen': 3,
              'allergen_name': 'Betula',
              'allergenicity': 2,
              'level': 4,
              'trend': 3,
              'week': 14,
            }
          ]));

      final result = await service.fetchSites(locationId: 1);
      expect(result.length, 1);
      expect(result.first.level, 4);
      expect(result.first.trend, 3);
    });
  });
}
