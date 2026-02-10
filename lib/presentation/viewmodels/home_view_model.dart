import 'package:alergeni/core/constants/severity_thresholds.dart';
import 'package:alergeni/data/models/allergen.dart';
import 'package:alergeni/data/models/allergen_types.dart';
import 'package:alergeni/data/models/concentrations.dart';
import 'package:alergeni/data/models/locations.dart';
import 'package:alergeni/data/models/pollens.dart';
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

  //--------------------------------------------------------------------------
  int get lowCount => _lowCount;

  //--------------------------------------------------------------------------
  int get mediumCount => _mediumCount;

  //--------------------------------------------------------------------------
  int get highCount => _highCount;

  //--------------------------------------------------------------------------
  List<Locations>? get locations => _locations;

  //--------------------------------------------------------------------------
  Locations? get selectedLocation => _selectedLocation;

  //--------------------------------------------------------------------------
  List<Allergen>? get allergens => _allergens;

  //--------------------------------------------------------------------------
  List<AllergenTypes>? get allergenTypes => _allergenTypes;

  //--------------------------------------------------------------------------
  List<Concentrations>? get concentrations => _concentrations;

  //--------------------------------------------------------------------------
  bool get isLoadingPollenData => _isLoadingPollenData;

  //--------------------------------------------------------------------------
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

    checkOffSeason();
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
  Future<void> fetchAllergens() async {
    try {
      _isLoadingAllergens = true;
      _errorMessage = null;
      notifyListeners();

      final allergens = await _pollenRepository.fetchAllergens();

      _allergens = allergens;
      _isLoadingAllergens = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoadingAllergens = false;
      notifyListeners();
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
  bool checkOffSeason() {
    final now = DateTime.now();
    return (now.month >= 10 || now.month <= 1);
  }

  //--------------------------------------------------------------------------
  Future<void> fetchPollenData() async {
    if (_selectedLocation == null) return;

    try {
      _isLoadingPollenData = true;
      _errorMessage = null;
      notifyListeners();

      // Step 1: Try to get today's pollen data for the selected location
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      var pollensResponse = await _pollenRepository
          .fetchPollensByLocationAndDate(_selectedLocation!.id, todayStr);

      Pollens? pollen;

      if (pollensResponse.results.isNotEmpty) {
        pollen = pollensResponse.results.first;
      } else {
        // If no data for today, try to get the most recent data for this location
        final lastYear = today.year - 1;
        final dateAfter = '$lastYear-01-01';
        pollensResponse = await _pollenRepository.fetchRecentPollensByLocation(
          _selectedLocation!.id,
          dateAfter: dateAfter,
        );
      }

      if (pollensResponse.results.isEmpty) {
        // No data - off season or no data for location
        final twoYearsAgo = today.year - 2;
        final dateAfter = '$twoYearsAgo-01-01';
        pollensResponse = await _pollenRepository.fetchRecentPollensByLocation(
          _selectedLocation!.id,
          dateAfter: dateAfter,
        );
      }

      if (pollensResponse.results.isEmpty) {
        _concentrations = null;
        selectedDate = null;
        _isLoadingPollenData = false;
        notifyListeners();
        return;
      }

      List<Concentrations> concentrations = [];

      // sort by date descending to get the most recent record
      final sortedPollens = pollensResponse.results.toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      for (var p in sortedPollens) {
        if (p.concentrationIds.isNotEmpty) {
          pollen = p;
          concentrations = await _pollenRepository.fetchConcentrationsByIds(
            pollen.concentrationIds,
          );

          if (concentrations.any((c) => c.value > 0)) {
            break;
          }
        }
      }

      if (pollen == null || concentrations.isEmpty) {
        _concentrations = null;
        selectedDate = null;
        _isLoadingPollenData = false;
        notifyListeners();
        return;
      }

      // Step 3: Count severity levels
      _lowCount = 0;
      _mediumCount = 0;
      _highCount = 0;

      for (var conc in concentrations) {
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

      // Step 5: Update state with all data
      _concentrations = concentrations;
      _pollenDate = pollen.date;
      selectedDate =
          '${pollen.date.day.toString().padLeft(2, '0')}.${pollen.date.month.toString().padLeft(2, '0')}.${pollen.date.year}.';
      _isLoadingPollenData = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoadingPollenData = false;
      notifyListeners();
    }
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
  void ensureOffSeasonNotice() {
    checkOffSeason();
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
}
