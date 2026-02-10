import 'package:alergeni/data/models/locations.dart';
import 'package:alergeni/data/repositories/pollen_repository.dart';
import 'package:flutter/material.dart';

class MapViewModel extends ChangeNotifier {
  final PollenRepository _pollenRepository;

  List<Locations>? _locations;
  bool _isLoading = true;
  String? _errorMessage;

  List<Locations>? get locations => _locations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  //--------------------------------------------------------------------------
  MapViewModel({required PollenRepository pollenRepository})
    : _pollenRepository = pollenRepository;

  //--------------------------------------------------------------------------
  Future<void> loadLocations() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final locations = await _pollenRepository.fetchLocations();

      _locations = locations;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  //--------------------------------------------------------------------------
  Future<void> refreshLocations() async {
    await loadLocations();
  }
}
