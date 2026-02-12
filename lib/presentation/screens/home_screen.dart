import 'package:alergeni/core/constants/severity_thresholds.dart';
import 'package:alergeni/core/theme/app_theme.dart';
import 'package:alergeni/data/models/allergen.dart';
import 'package:alergeni/presentation/viewmodels/home_view_model.dart';
import 'package:alergeni/presentation/widgets/empty_state.dart';
import 'package:alergeni/presentation/widgets/error_state.dart';
import 'package:alergeni/presentation/widgets/loading_state.dart';
import 'package:alergeni/presentation/widgets/location_selector_card.dart';
import 'package:alergeni/presentation/widgets/today_snapshot_card.dart';
import 'package:alergeni/presentation/widgets/top_allergens_card.dart';
import 'package:alergeni/presentation/widgets/weekly_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showOffSeasonDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Obaveštenje'),
        content: const Text(
          'Sezona praćenja polena je završena. \n\n'
          'Novi ciklus praćenja počinje u Februaru naredne godine.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<HomeViewModel>();
    if (viewModel.checkOffSeason()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!viewModel.hasShownOffSeasonMessage) {
          _showOffSeasonDialog(context);
          viewModel.hasShownOffSeasonMessage = true;
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Početna'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      body: _buildBody(context, context.watch<HomeViewModel>()),
    );
  }

  Widget _buildBody(BuildContext context, HomeViewModel viewModel) {
    if (viewModel.isLoading) {
      return const LoadingState();
    }

    if (viewModel.errorMessage != null) {
      return ErrorState(
        message: viewModel.errorMessage!,
        onRetry: viewModel.fetchLocations,
      );
    }

    if (viewModel.locations == null || viewModel.locations!.isEmpty) {
      return const EmptyState(title: 'Nema dostupnih lokacija.');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LocationSelectorCard(
            locations: viewModel.locations!,
            selectedLocation: viewModel.selectedLocation,
            onLocationChanged: viewModel.selectLocation,
            onMyLocationPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Geolokacija će uskoro biti dostupna'),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          if (viewModel.selectedLocation != null &&
              (viewModel.concentrations != null &&
                      viewModel.concentrations!.isNotEmpty ||
                  viewModel.siteData != null &&
                      viewModel.siteData!.isNotEmpty)) ...[
            _buildWeeklySummaryCard(context, viewModel),
            const SizedBox(height: 20),
          ],

          if (viewModel.concentrations != null &&
              viewModel.concentrations!.isNotEmpty) ...[
            TodaySnapshotCard(items: _buildSnapshotItems(viewModel)),
            const SizedBox(height: 20),
          ],

          if (viewModel.concentrations != null &&
              viewModel.concentrations!.isNotEmpty) ...[
            _buildTopAllergensSection(context, viewModel),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildWeeklySummaryCard(BuildContext context, HomeViewModel viewModel) {
    final overallStatus =
        viewModel.siteData != null && viewModel.siteData!.isNotEmpty
            ? viewModel.fiveTierLevel
            : viewModel.getOverallStatus();

    final statusColor =
        viewModel.siteData != null && viewModel.siteData!.isNotEmpty
            ? viewModel.getFiveTierColor()
            : viewModel.getOverallStatusColor();

    final totalCount =
        viewModel.lowCount + viewModel.mediumCount + viewModel.highCount;

    final percentage = totalCount > 0
        ? ((viewModel.mediumCount + viewModel.highCount) / totalCount * 100)
            .toStringAsFixed(0)
        : '0';

    final weekOrDateLabel =
        viewModel.siteData != null && viewModel.siteData!.isNotEmpty
            ? 'Nedelja ${viewModel.siteData!.first.week}'
            : viewModel.selectedDate ?? 'N/A';

    return WeeklySummaryCard(
      locationName: viewModel.selectedLocation!.name,
      overallStatus: overallStatus,
      statusColor: statusColor,
      weekOrDateLabel: weekOrDateLabel,
      isShowingHistoricalData: viewModel.isShowingHistoricalData,
      percentage: percentage,
    );
  }

  List<SnapshotColumnItem> _buildSnapshotItems(HomeViewModel viewModel) {
    final typeData = _getTypeData(viewModel);
    return [
      SnapshotColumnItem(
        icon: Icons.park,
        label: 'Drveće',
        color: typeData[1]?['color'] ?? Colors.grey,
      ),
      SnapshotColumnItem(
        icon: Icons.grass,
        label: 'Trave',
        color: typeData[2]?['color'] ?? Colors.grey,
      ),
      SnapshotColumnItem(
        icon: Icons.eco,
        label: 'Korovi',
        color: typeData[3]?['color'] ?? Colors.grey,
      ),
    ];
  }

  Widget _buildTopAllergensSection(
      BuildContext context, HomeViewModel viewModel) {
    if (viewModel.isLoadingPollenData) {
      return const TopAllergensCardLoading();
    }

    if (viewModel.allergens == null || viewModel.allergens!.isEmpty) {
      return const SizedBox.shrink();
    }

    final activeConcentrations = viewModel.concentrations!
        .where((conc) => conc.value > 0)
        .toList();

    if (activeConcentrations.isEmpty) {
      return const SizedBox.shrink();
    }

    activeConcentrations.sort((a, b) => b.value.compareTo(a.value));
    final topAllergens = activeConcentrations.take(5).toList();

    final maxValue = topAllergens.isNotEmpty
        ? topAllergens.first.value.toDouble()
        : 1.0;

    final trendMap = <int, int>{};
    if (viewModel.siteData != null) {
      for (var site in viewModel.siteData!) {
        trendMap[site.allergenId] = site.trend;
      }
    }

    final items = topAllergens.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final conc = entry.value;
      final allergen = viewModel.allergens!.firstWhere(
        (a) => a.id == conc.allergenId,
        orElse: () => viewModel.allergens!.first,
      );
      final color = _getAllergenicityColor(allergen, conc.value);
      final severityLabel = _getCombinedSeverityLabel(allergen, conc.value);
      final trend = trendMap[allergen.id];
      final trendIcon = _getTrendIcon(trend);

      return TopAllergenItem(
        index: index,
        name: allergen.localizedName,
        allergenicityLabel: allergen.allergenicityDisplayLocalized,
        color: color,
        value: conc.value,
        severityLabel: severityLabel,
        trendIcon: trendIcon,
      );
    }).toList();

    return TopAllergensCard(
      items: items,
      maxValue: maxValue,
      showTrendHint: viewModel.siteData != null &&
          viewModel.siteData!.isNotEmpty,
    );
  }

  // ====== HELPER METHODS ======
  Map<int, Map<String, dynamic>> _getTypeData(HomeViewModel viewModel) {
    final result = <int, Map<String, dynamic>>{};

    if (viewModel.allergens == null || viewModel.concentrations == null) {
      return result;
    }

    for (var typeId in [1, 2, 3]) {
      final allergensForType = <AllergenWithConcentration>[];

      for (var conc in viewModel.concentrations!) {
        if (conc.value == 0) continue;

        try {
          final allergen = viewModel.allergens!.firstWhere(
            (a) => a.id == conc.allergenId,
          );
          if (allergen.type == typeId) {
            allergensForType.add(
              AllergenWithConcentration(allergen, conc.value),
            );
          }
        } catch (e) {
          continue;
        }
      }

      if (allergensForType.isEmpty) {
        result[typeId] = {
          'severity': 'Nema',
          'color': Colors.grey,
          'allergenicityLabel': '',
        };
      } else {
        allergensForType.sort((a, b) {
          final dangerA = a.concentration * a.allergen.allergenicityIndex;
          final dangerB = b.concentration * b.allergen.allergenicityIndex;
          return dangerB.compareTo(dangerA);
        });

        final mostDangerous = allergensForType.first;
        result[typeId] = {
          'severity': _getSeverityLabel(mostDangerous.concentration),
          'color': _getAllergenicityColor(
            mostDangerous.allergen,
            mostDangerous.concentration,
          ),
          'allergenicityLabel': mostDangerous.allergen.allergenicityDisplay,
        };
      }
    }

    return result;
  }

  Color _getAllergenicityColor(Allergen allergen, int concentration) {
    Color baseColor;
    switch (allergen.allergenicityIndex) {
      case 1:
        baseColor = AppTheme.severityLow;
        break;
      case 2:
        baseColor = AppTheme.severityMedium;
        break;
      case 3:
        baseColor = AppTheme.severityHigh;
        break;
      default:
        baseColor = Colors.grey;
    }

    if (concentration >= SeverityThresholds.highMin) {
      return baseColor;
    } else if (concentration >= SeverityThresholds.mediumMin) {
      return _lightenColor(baseColor, 0.1);
    } else {
      return _lightenColor(baseColor, 0.3);
    }
  }

  Color _lightenColor(Color color, double factor) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + factor).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  String _getCombinedSeverityLabel(Allergen allergen, int concentration) {
    final concentrationLevel = _getSeverityLabel(concentration);
    return '$concentrationLevel ';
  }

  String _getSeverityLabel(int value) {
    if (value >= SeverityThresholds.highMin) {
      return 'Visoka';
    } else if (value >= SeverityThresholds.mediumMin) {
      return 'Srednja';
    } else if (value >= SeverityThresholds.lowMin) {
      return 'Niska';
    }
    return 'Nema';
  }

  IconData? _getTrendIcon(int? trend) {
    if (trend == null) return null;

    switch (trend) {
      case 1:
        return Icons.trending_down; // Declining
      case 2:
        return Icons.trending_flat; // Stable
      case 3:
        return Icons.trending_up; // Rising
      default:
        return null;
    }
  }
}

class AllergenWithConcentration {
  final Allergen allergen;
  final int concentration;

  AllergenWithConcentration(this.allergen, this.concentration);
}
