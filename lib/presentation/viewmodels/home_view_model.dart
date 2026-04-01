import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udahni/core/constants/severity_thresholds.dart';
import 'package:udahni/data/models/allergen.dart';
import 'package:udahni/data/models/allergen_types.dart';
import 'package:udahni/data/models/concentrations.dart';
import 'package:udahni/data/models/locations.dart';
import 'package:udahni/data/models/paginated_response.dart';
import 'package:udahni/data/models/pollens.dart';
import 'package:udahni/data/models/site.dart';
import 'package:udahni/core/helpers/level_helper.dart';
import 'package:udahni/core/helpers/severity_helper.dart';
import 'package:udahni/data/repositories/pollen_repository.dart';

class HomeViewModel extends ChangeNotifier {
  final PollenRepository _pollenRepository;
  static const String _selectedLocationIdKey = 'selected_location_id';

  List<Locations>? _locations;
  String? _errorMessage;
  Locations? _selectedLocation;
  List<Allergen>? _allergens;
  List<AllergenTypes>? _allergenTypes;
  List<Concentrations>? _concentrations;
  List<Site>? _siteData;
  bool _isLoadingPollenData = false;
  bool _isLocatingNearestLocation = false;
  String? selectedDate;
  bool _hasShownOffSeasonMessage = false;
  DateTime? _pollenDate;

  int _lowCount = 0;
  int _mediumCount = 0;
  int _highCount = 0;

  bool _isLoadingLocations = false;
  bool _isLoadingAllergens = false;
  bool _isLoadingAllergenTypes = false;

  bool get isLoading =>
      _isLoadingLocations || _isLoadingAllergens || _isLoadingAllergenTypes;

  //--------------------------------------------------------------------------
  bool get isShowingHistoricalData {
    if (_pollenDate == null) return false;
    final now = DateTime.now();
    final difference = now.difference(_pollenDate!).inDays;
    return difference > 7;
  }

  //--------------------------------------------------------------------------
  String? get errorMessage => _errorMessage;
  int get lowCount => _lowCount;
  int get mediumCount => _mediumCount;
  int get highCount => _highCount;
  List<Locations>? get locations => _locations;
  Locations? get selectedLocation => _selectedLocation;
  List<Allergen>? get allergens => _allergens;
  List<AllergenTypes>? get allergenTypes => _allergenTypes;
  List<Site>? get siteData => _siteData;
  List<Concentrations>? get concentrations => _concentrations;
  bool get isLoadingPollenData => _isLoadingPollenData;
  bool get isLocatingNearestLocation => _isLocatingNearestLocation;
  bool get hasShownOffSeasonMessage => _hasShownOffSeasonMessage;

  //--------------------------------------------------------------------------
  set hasShownOffSeasonMessage(bool value) {
    _hasShownOffSeasonMessage = value;
    notifyListeners();
  }

  //--------------------------------------------------------------------------
  HomeViewModel({required PollenRepository pollenRepository})
    : _pollenRepository = pollenRepository;

  //--------------------------------------------------------------------------
  Future<void> loadInitialData() async {
    await Future.wait([
      fetchLocations(),
      fetchAllergens(),
      fetchAllergenTypes(),
    ]);

    _updateOffSeasonState();

    // If we preselect a location on startup, load its pollen data as well.
    if (_selectedLocation != null) {
      await fetchPollenData();
    }
  }

  //--------------------------------------------------------------------------
  Future<void> fetchLocations() async {
    try {
      _isLoadingLocations = true;
      _errorMessage = null;
      notifyListeners();

      final locations = await _pollenRepository.fetchLocations();
      int? preferredLocationId = _selectedLocation?.id;
      preferredLocationId ??= await _readSavedLocationId();

      _locations = locations;
      if (locations.isEmpty) {
        _selectedLocation = null;
      } else if (preferredLocationId == null) {
        _selectedLocation = locations.first;
      } else {
        _selectedLocation =
            _findLocationById(locations, preferredLocationId) ??
            locations.first;
      }

      if (_selectedLocation != null) {
        unawaited(_saveSelectedLocationId(_selectedLocation!.id));
      }
      _isLoadingLocations = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoadingLocations = false;
      notifyListeners();
    }
  }

  //--------------------------------------------------------------------------
  Future<List<Allergen>> fetchAllergens() async {
    try {
      _isLoadingAllergens = true;
      _errorMessage = null;
      notifyListeners();

      final allergens = await _pollenRepository.fetchAllergens();

      _allergens = allergens;
      _isLoadingAllergens = false;
      notifyListeners();
      return allergens;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoadingAllergens = false;
      notifyListeners();
      return _allergens ?? [];
    }
  }

  //--------------------------------------------------------------------------
  Future<void> fetchAllergenTypes() async {
    try {
      _isLoadingAllergenTypes = true;
      _errorMessage = null;
      notifyListeners();

      final allergenTypes = await _pollenRepository.fetchAllergenTypes();

      _allergenTypes = allergenTypes;
      _isLoadingAllergenTypes = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoadingAllergenTypes = false;
      notifyListeners();
    }
  }

  //--------------------------------------------------------------------------
  bool get shouldShowOffSeasonDialog {
    return _isOffSeason() && !_hasShownOffSeasonMessage;
  }

  //--------------------------------------------------------------------------
  bool _isOffSeason() {
    final now = DateTime.now();
    return (now.month >= 10 || now.month <= 1);
  }

  //--------------------------------------------------------------------------
  void _updateOffSeasonState() {
    final isOffSeason = _isOffSeason();
    if (!isOffSeason && _hasShownOffSeasonMessage) {
      _hasShownOffSeasonMessage = false;
      notifyListeners();
    }
  }

  //--------------------------------------------------------------------------
  bool checkOffSeason() {
    return _isOffSeason();
  }

  //--------------------------------------------------------------------------
  Future<void> fetchSiteData() async {
    if (_selectedLocation == null) return;

    try {
      final siteData = await _pollenRepository.fetchSites(
        locationId: _selectedLocation!.id,
      );
      _siteData = siteData;
      notifyListeners();
    } catch (e) {
      _siteData = null;
      notifyListeners();
    }
  }

  //--------------------------------------------------------------------------
  Future<void> fetchPollenData() async {
    if (_selectedLocation == null) return;

    try {
      _isLoadingPollenData = true;
      _errorMessage = null;
      notifyListeners();

      await Future.wait([fetchPollenConcentrationData(), fetchSiteData()]);

      _isLoadingPollenData = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoadingPollenData = false;
      notifyListeners();
    }
  }

  //--------------------------------------------------------------------------
  Future<void> fetchPollenConcentrationData() async {
    final today = DateTime.now();
    final locationId = _selectedLocation!.id;
    final pollensResponse = await _fetchPreferredPollensForLocation(
      locationId: locationId,
      today: today,
    );

    final snapshot = await _selectLatestSnapshotWithPositiveConcentrations(
      pollensResponse.results,
    );
    if (snapshot == null) {
      _clearSelectedPollenState();
      return;
    }

    _updateSeverityCounts(snapshot.concentrations);
    _updateSelectedPollenState(
      pollen: snapshot.pollen,
      concentrations: snapshot.concentrations,
    );
  }

  //--------------------------------------------------------------------------
  Future<PaginatedResponse<Pollens>> _fetchPreferredPollensForLocation({
    required int locationId,
    required DateTime today,
  }) async {
    final todayResponse = await _pollenRepository.fetchPollensByLocationAndDate(
      locationId,
      _formatApiDate(today),
    );
    if (todayResponse.results.isNotEmpty) {
      return todayResponse;
    }

    final oneYearBack = await _pollenRepository.fetchRecentPollensByLocation(
      locationId,
      dateAfter: '${today.year - 1}-01-01',
    );
    if (oneYearBack.results.isNotEmpty) {
      return oneYearBack;
    }

    return _pollenRepository.fetchRecentPollensByLocation(
      locationId,
      dateAfter: '${today.year - 2}-01-01',
    );
  }

  //--------------------------------------------------------------------------
  Future<_PollenSnapshot?> _selectLatestSnapshotWithPositiveConcentrations(
    List<Pollens> pollens,
  ) async {
    if (pollens.isEmpty) return null;

    final sortedPollens = pollens.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    for (final pollen in sortedPollens) {
      if (pollen.concentrationIds.isEmpty) continue;

      final concentrations = await _pollenRepository.fetchConcentrationsByIds(
        pollen.concentrationIds,
      );
      if (_hasPositiveConcentration(concentrations)) {
        return _PollenSnapshot(pollen: pollen, concentrations: concentrations);
      }
    }

    return null;
  }

  //--------------------------------------------------------------------------
  bool _hasPositiveConcentration(List<Concentrations> concentrations) {
    return concentrations.any((c) => c.value > 0);
  }

  //--------------------------------------------------------------------------
  void _clearSelectedPollenState() {
    _concentrations = null;
    selectedDate = null;
    _pollenDate = null;
  }

  //--------------------------------------------------------------------------
  void _updateSelectedPollenState({
    required Pollens pollen,
    required List<Concentrations> concentrations,
  }) {
    _concentrations = concentrations;
    _pollenDate = pollen.date;
    selectedDate = _formatDisplayDate(pollen.date);
  }

  //--------------------------------------------------------------------------
  void _updateSeverityCounts(List<Concentrations> concentrations) {
    _lowCount = 0;
    _mediumCount = 0;
    _highCount = 0;

    for (final conc in concentrations) {
      if (conc.value >= SeverityThresholds.lowMin &&
          conc.value <= SeverityThresholds.lowMax) {
        _lowCount++;
      } else if (conc.value >= SeverityThresholds.mediumMin &&
          conc.value <= SeverityThresholds.mediumMax) {
        _mediumCount++;
      } else if (conc.value >= SeverityThresholds.highMin) {
        _highCount++;
      }
    }
  }

  //--------------------------------------------------------------------------
  String _formatApiDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  //--------------------------------------------------------------------------
  String _formatDisplayDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}.';
  }

  //--------------------------------------------------------------------------
  void selectLocation(Locations location) {
    _selectedLocation = location;
    unawaited(_saveSelectedLocationId(location.id));
    fetchPollenData();
  }

  //--------------------------------------------------------------------------
  void refreshPollenData() {
    fetchPollenData();
  }

  //--------------------------------------------------------------------------
  Locations? _findLocationById(List<Locations> locations, int id) {
    for (final location in locations) {
      if (location.id == id) {
        return location;
      }
    }
    return null;
  }

  //--------------------------------------------------------------------------
  Future<void> _saveSelectedLocationId(int locationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_selectedLocationIdKey, locationId);
    } catch (_) {
      // Persistence failure should not block core app flow.
    }
  }

  //--------------------------------------------------------------------------
  Future<int?> _readSavedLocationId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_selectedLocationIdKey);
    } catch (_) {
      return null;
    }
  }

  //--------------------------------------------------------------------------
  String getOverallStatus() {
    if (_highCount > 0) {
      return 'Visok';
    } else if (_mediumCount > 0) {
      return 'Srednji';
    } else if (_lowCount > 0) {
      return 'Nizak';
    } else {
      return 'Nema koncentracije';
    }
  }

  //--------------------------------------------------------------------------
  Color getOverallStatusColor() {
    if (_highCount > 0) {
      return Colors.red;
    } else if (_mediumCount > 0) {
      return Colors.orange;
    } else if (_lowCount > 0) {
      return Colors.green;
    } else {
      return Colors.grey;
    }
  }

  //--------------------------------------------------------------------------
  String get fiveTierLevel {
    if (_siteData == null || _siteData!.isEmpty) return getOverallStatus();

    final maxLevel = _siteData!
        .map((s) => s.level)
        .reduce((a, b) => a > b ? a : b);

    return LevelHelper.levelToLabel(maxLevel);
  }

  //--------------------------------------------------------------------------
  Color getFiveTierColor() {
    if (_siteData == null || _siteData!.isEmpty) return getOverallStatusColor();

    final maxLevel = _siteData!
        .map((s) => s.level)
        .reduce((a, b) => a > b ? a : b);

    return LevelHelper.levelToColor(maxLevel);
  }

  //--------------------------------------------------------------------------
  Map<int, TypeSeverityData> get typeDataMap {
    final result = <int, TypeSeverityData>{};

    if (_allergens == null || _concentrations == null) return result;

    for (var typeId in [1, 2, 3]) {
      final allergensForType = <AllergenWithConcentration>[];

      for (var conc in _concentrations!) {
        if (conc.value == 0) continue;

        final allergen = _allergens!.cast<Allergen?>().firstWhere(
          (a) => a!.id == conc.allergenId,
          orElse: () => null,
        );
        if (allergen != null && allergen.type == typeId) {
          allergensForType.add(
            AllergenWithConcentration(allergen, conc.value),
          );
        }
      }

      if (allergensForType.isEmpty) {
        result[typeId] = const TypeSeverityData(
          severity: 'Nema',
          color: Colors.grey,
          allergenicityLabel: '',
        );
      } else {
        allergensForType.sort((a, b) {
          final dangerA = a.concentration * a.allergen.allergenicityIndex;
          final dangerB = b.concentration * b.allergen.allergenicityIndex;
          return dangerB.compareTo(dangerA);
        });

        final mostDangerous = allergensForType.first;
        result[typeId] = TypeSeverityData(
          severity: SeverityHelper.concentrationLabel(
            mostDangerous.concentration,
          ),
          color: SeverityHelper.allergenicityColorForConcentration(
            allergenicityIndex: mostDangerous.allergen.allergenicityIndex,
            concentration: mostDangerous.concentration,
          ),
          allergenicityLabel: SeverityHelper.allergenicityLabel(
            mostDangerous.allergen.allergenicityIndex,
          ),
        );
      }
    }

    return result;
  }

  //--------------------------------------------------------------------------
  Future<Locations> selectNearestLocationFromDevice() async {
    if (_isLocatingNearestLocation) {
      throw Exception('Lociranje najbliže stanice je već u toku.');
    }

    _isLocatingNearestLocation = true;
    notifyListeners();

    try {
      final currentLocations = _locations;
      if (currentLocations == null || currentLocations.isEmpty) {
        throw Exception('Nema dostupnih lokacija za izbor.');
      }

      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        throw Exception('Uključite geolokaciju na uređaju.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception(
          'Dozvolite pristup geolokaciji da bismo našli najbližu stanicu.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Pristup geolokaciji je trajno odbijen. Omogućite ga u podešavanjima aplikacije.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      var minDistanceMeters = double.infinity;
      Locations? nearestLocation;
      for (final location in currentLocations) {
        final distanceMeters = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          location.latitude,
          location.longitude,
        );
        if (distanceMeters < minDistanceMeters) {
          minDistanceMeters = distanceMeters;
          nearestLocation = location;
        }
      }

      if (nearestLocation == null) {
        throw Exception('Najbliža lokacija nije pronađena.');
      }

      _selectedLocation = nearestLocation;
      await _saveSelectedLocationId(nearestLocation.id);
      await fetchPollenData();
      return nearestLocation;
    } finally {
      _isLocatingNearestLocation = false;
      notifyListeners();
    }
  }
}

class _PollenSnapshot {
  final Pollens pollen;
  final List<Concentrations> concentrations;

  const _PollenSnapshot({required this.pollen, required this.concentrations});
}

class AllergenWithConcentration {
  final Allergen allergen;
  final int concentration;

  AllergenWithConcentration(this.allergen, this.concentration);
}

class TypeSeverityData {
  final String severity;
  final Color color;
  final String allergenicityLabel;

  const TypeSeverityData({
    required this.severity,
    required this.color,
    required this.allergenicityLabel,
  });
}
