import 'dart:async';

import 'package:alergeni/data/models/locations.dart';
import 'package:alergeni/data/models/site.dart';
import 'package:alergeni/data/repositories/pollen_repository.dart';
import 'package:flutter/material.dart';

class MapViewModel extends ChangeNotifier {
  final PollenRepository _pollenRepository;

  List<Locations>? _locations;
  bool _isLoading = true;
  String? _errorMessage;
  final Map<int, MapLocationSummary> _locationSummaryCache = {};

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
      _locationSummaryCache.clear();
      notifyListeners();

      final locations = await _pollenRepository.fetchLocations();

      _locations = locations;
      _isLoading = false;
      notifyListeners();
      unawaited(_prefetchLocationSummaries(locations));
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

  //--------------------------------------------------------------------------
  Future<MapLocationSummary> getLocationSummary({
    required int locationId,
  }) async {
    final cached = _locationSummaryCache[locationId];
    if (cached != null) {
      return cached;
    }

    final sites = await _pollenRepository.fetchSites(locationId: locationId);
    final summary = _buildSummaryFromSites(sites);
    _locationSummaryCache[locationId] = summary;
    return summary;
  }

  //--------------------------------------------------------------------------
  MapLocationSummary? getLocationSummaryIfCached({required int locationId}) {
    return _locationSummaryCache[locationId];
  }

  //--------------------------------------------------------------------------
  Color getPinColorForLocation(int locationId) {
    return _locationSummaryCache[locationId]?.pinColor ?? Colors.grey.shade600;
  }

  //--------------------------------------------------------------------------
  Color getPinColorForTrendValue(int? trend) {
    return _trendToPinColor(trend);
  }

  //--------------------------------------------------------------------------
  MapLocationSummary _buildSummaryFromSites(List<Site> sites) {
    if (sites.isEmpty) {
      return _noDataSummary();
    }

    final maxLevel = sites
        .map((site) => site.level)
        .reduce((a, b) => a > b ? a : b);
    final trend = _mostCommonTrend(sites);

    return MapLocationSummary(
      hasData: true,
      riskLabel: _levelToLabel(maxLevel),
      riskColor: _levelToColor(maxLevel),
      trendLabel: _trendToLabel(trend),
      trendIcon: _trendToIcon(trend),
      trendValue: trend,
      pinColor: _trendToPinColor(trend),
      week: sites.first.week,
    );
  }

  //--------------------------------------------------------------------------
  Future<void> _prefetchLocationSummaries(List<Locations> locations) async {
    var hasUpdates = false;
    for (final location in locations) {
      if (_locationSummaryCache.containsKey(location.id)) continue;
      try {
        final sites = await _pollenRepository.fetchSites(
          locationId: location.id,
        );
        _locationSummaryCache[location.id] = _buildSummaryFromSites(sites);
      } catch (_) {
        _locationSummaryCache[location.id] = _noDataSummary();
      }
      hasUpdates = true;
    }

    if (hasUpdates) {
      notifyListeners();
    }
  }

  //--------------------------------------------------------------------------
  MapLocationSummary _noDataSummary() {
    return MapLocationSummary(
      hasData: false,
      riskLabel: 'Nema podataka',
      riskColor: Colors.grey,
      trendLabel: 'Trend nije dostupan',
      trendIcon: Icons.help_outline,
      trendValue: null,
      pinColor: _trendToPinColor(null),
      week: null,
    );
  }

  //--------------------------------------------------------------------------
  int? _mostCommonTrend(List<Site> sites) {
    final counts = <int, int>{};
    for (final site in sites) {
      counts[site.trend] = (counts[site.trend] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;

    return counts.entries
        .reduce(
          (best, current) =>
              current.value > best.value ||
                  (current.value == best.value && current.key > best.key)
              ? current
              : best,
        )
        .key;
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
  Color _levelToColor(int level) {
    switch (level) {
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

  //--------------------------------------------------------------------------
  String _trendToLabel(int? trend) {
    switch (trend) {
      case 1:
        return 'Opadajući trend';
      case 2:
        return 'Stabilan trend';
      case 3:
        return 'Rastući trend';
      default:
        return 'Trend nije dostupan';
    }
  }

  //--------------------------------------------------------------------------
  IconData _trendToIcon(int? trend) {
    switch (trend) {
      case 1:
        return Icons.trending_down;
      case 2:
        return Icons.trending_flat;
      case 3:
        return Icons.trending_up;
      default:
        return Icons.help_outline;
    }
  }

  //--------------------------------------------------------------------------
  Color _trendToPinColor(int? trend) {
    switch (trend) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.grey.shade600;
    }
  }
}

class MapLocationSummary {
  final bool hasData;
  final String riskLabel;
  final Color riskColor;
  final String trendLabel;
  final IconData trendIcon;
  final int? trendValue;
  final Color pinColor;
  final int? week;

  const MapLocationSummary({
    required this.hasData,
    required this.riskLabel,
    required this.riskColor,
    required this.trendLabel,
    required this.trendIcon,
    required this.trendValue,
    required this.pinColor,
    required this.week,
  });
}
