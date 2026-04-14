// ABOUTME: Tests for the PaginatedResponse generic model's JSON serialization.
// ABOUTME: Covers fromJson with typed results and hasNextPage/hasPreviousPage helpers.

import 'package:flutter_test/flutter_test.dart';
import 'package:udahni/data/models/allergen_types.dart';
import 'package:udahni/data/models/paginated_response.dart';

void main() {
  group('PaginatedResponse.fromJson', () {
    test('parses count, next, previous, and results', () {
      final json = {
        'count': 10,
        'next': 'http://example.com/page=2',
        'previous': null,
        'results': [
          {'id': 1, 'name': 'Drveće'},
          {'id': 2, 'name': 'Trave'},
        ],
      };

      final response = PaginatedResponse.fromJson(json, AllergenTypes.fromJson);
      expect(response.count, 10);
      expect(response.next, 'http://example.com/page=2');
      expect(response.previous, isNull);
      expect(response.results.length, 2);
      expect(response.results[0].id, 1);
      expect(response.results[1].name, 'Trave');
    });

    test('parses empty results list', () {
      final json = {
        'count': 0,
        'next': null,
        'previous': null,
        'results': <dynamic>[],
      };
      final response = PaginatedResponse.fromJson(json, AllergenTypes.fromJson);
      expect(response.results, isEmpty);
    });
  });

  group('PaginatedResponse.hasNextPage', () {
    test('returns true when next is non-null', () {
      final r = PaginatedResponse<AllergenTypes>(
        count: 10,
        next: 'http://example.com/page=2',
        previous: null,
        results: [],
      );
      expect(r.hasNextPage, isTrue);
    });

    test('returns false when next is null', () {
      final r = PaginatedResponse<AllergenTypes>(
        count: 5,
        next: null,
        previous: null,
        results: [],
      );
      expect(r.hasNextPage, isFalse);
    });
  });

  group('PaginatedResponse.hasPreviousPage', () {
    test('returns true when previous is non-null', () {
      final r = PaginatedResponse<AllergenTypes>(
        count: 10,
        next: null,
        previous: 'http://example.com/page=1',
        results: [],
      );
      expect(r.hasPreviousPage, isTrue);
    });

    test('returns false when previous is null', () {
      final r = PaginatedResponse<AllergenTypes>(
        count: 5,
        next: null,
        previous: null,
        results: [],
      );
      expect(r.hasPreviousPage, isFalse);
    });
  });
}
