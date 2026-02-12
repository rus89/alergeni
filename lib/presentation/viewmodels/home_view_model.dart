import 'package:alergeni/core/constants/severity_thresholds.dart';
import 'package:alergeni/data/models/allergen.dart';
import 'package:alergeni/data/models/allergen_types.dart';
import 'package:alergeni/data/models/concentrations.dart';
import 'package:alergeni/data/models/locations.dart';
import 'package:alergeni/data/models/paginated_response.dart';
import 'package:alergeni/data/models/pollens.dart';
import 'package:alergeni/data/models/site.dart';
import 'package:alergeni/data/repositories/pollen_repository.dart';
import 'package:flutter/material.dart';

class HomeViewModel extends ChangeNotifier {
  final PollenRepository _pollenRepository;

  List<Locations>? _locations;
  String? _errorMessage;
  Locations? _selectedLocation;
  List<Allergen>? _allergens;
  List<AllergenTypes>? _allergenTypes;
  List<Concentrations>? _concentrations;
  List<Site>? _siteData;
  bool _isLoadingPollenData = false;
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
  }

  //--------------------------------------------------------------------------
  Future<void> fetchLocations() async {
    try {
      _isLoadingLocations = true;
      _errorMessage = null;
      notifyListeners();

      final locations = await _pollenRepository.fetchLocations();

      _locations = locations;
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
      _allergens = null;
      _errorMessage = e.toString();
      _isLoadingAllergens = false;
      notifyListeners();
      return [];
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
    fetchPollenData();
  }

  //--------------------------------------------------------------------------
  void refreshPollenData() {
    fetchPollenData();
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

    return _levelToLabel(maxLevel);
  }

  //--------------------------------------------------------------------------
  String _levelToLabel(int level) {
    switch (level) {
      case 1:
        return 'Vrlo niska';
      case 2:
        return 'Niska';
      case 3:
        return 'Srednja';
      case 4:
        return 'Visoka';
      case 5:
        return 'Vrlo visoka';
      default:
        return 'Nepoznato';
    }
  }

  //--------------------------------------------------------------------------
  Color getFiveTierColor() {
    if (_siteData == null || _siteData!.isEmpty) return getOverallStatusColor();

    final maxLevel = _siteData!
        .map((s) => s.level)
        .reduce((a, b) => a > b ? a : b);

    switch (maxLevel) {
      case 1:
        return Colors.lightGreen;
      case 2:
        return Colors.green;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.redAccent;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _PollenSnapshot {
  final Pollens pollen;
  final List<Concentrations> concentrations;

  const _PollenSnapshot({required this.pollen, required this.concentrations});
}
