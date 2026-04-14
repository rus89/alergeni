// ABOUTME: Factory functions for building model instances in tests.
// ABOUTME: All fields have sensible defaults so callers only override what matters.

import 'package:udahni/data/models/allergen.dart';
import 'package:udahni/data/models/allergen_types.dart';
import 'package:udahni/data/models/concentrations.dart';
import 'package:udahni/data/models/locations.dart';
import 'package:udahni/data/models/paginated_response.dart';
import 'package:udahni/data/models/pollens.dart';
import 'package:udahni/data/models/site.dart';

Allergen makeAllergen({
  int id = 1,
  String name = 'Betula',
  String localizedName = 'Breza',
  int marginTop = 0,
  int marginBottom = 0,
  int type = 1,
  int allergenicityIndex = 2,
  String allergenicityDisplay = 'moderate',
}) {
  return Allergen(
    id: id,
    name: name,
    localizedName: localizedName,
    marginTop: marginTop,
    marginBottom: marginBottom,
    type: type,
    allergenicityIndex: allergenicityIndex,
    allergenicityDisplay: allergenicityDisplay,
  );
}

AllergenTypes makeAllergenTypes({int id = 1, String name = 'Drveće'}) {
  return AllergenTypes(id: id, name: name);
}

Concentrations makeConcentrations({
  int id = 1,
  int allergenId = 1,
  int value = 10,
  int pollenId = 1,
}) {
  return Concentrations(
    id: id,
    allergenId: allergenId,
    value: value,
    pollenId: pollenId,
  );
}

Locations makeLocations({
  int id = 1,
  String name = 'Beograd',
  double latitude = 44.8125,
  double longitude = 20.4612,
  String description = 'Beograd monitoring station',
}) {
  return Locations(
    id: id,
    name: name,
    latitude: latitude,
    longitude: longitude,
    description: description,
  );
}

Pollens makePollens({
  int id = 1,
  int locationId = 1,
  DateTime? date,
  List<int> concentrationIds = const [1, 2],
}) {
  return Pollens(
    id: id,
    locationId: locationId,
    date: date ?? DateTime(2026, 4, 1),
    concentrationIds: concentrationIds,
  );
}

Site makeSite({
  int locationId = 1,
  String? date,
  int allergenId = 1,
  String? allergenName = 'Betula',
  int allergenicityIndex = 2,
  int level = 3,
  int trend = 2,
  int week = 14,
}) {
  return Site(
    locationId: locationId,
    date: date,
    allergenId: allergenId,
    allergenName: allergenName,
    allergenicityIndex: allergenicityIndex,
    level: level,
    trend: trend,
    week: week,
  );
}

PaginatedResponse<T> makePaginatedResponse<T>({
  int count = 0,
  String? next,
  String? previous,
  List<T> results = const [],
}) {
  return PaginatedResponse<T>(
    count: count,
    next: next,
    previous: previous,
    results: results,
  );
}
