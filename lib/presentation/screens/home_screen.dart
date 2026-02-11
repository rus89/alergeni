import 'package:alergeni/core/constants/severity_thresholds.dart';
import 'package:alergeni/core/theme/app_theme.dart';
import 'package:alergeni/data/models/allergen.dart';
import 'package:alergeni/data/models/locations.dart';
import 'package:alergeni/presentation/viewmodels/home_view_model.dart';
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
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Greška: ${viewModel.errorMessage}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: viewModel.fetchLocations,
              child: const Text('Pokušaj ponovo'),
            ),
          ],
        ),
      );
    }

    if (viewModel.locations == null || viewModel.locations!.isEmpty) {
      return const Center(child: Text('Nema dostupnih lokacija.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. LOCATION SELECTOR
          _buildLocationSelector(context, viewModel),
          const SizedBox(height: 20),

          // 2. WEEKLY SUMMARY CARD (now with 5-tier if available)
          if (viewModel.selectedLocation != null &&
              (viewModel.concentrations != null &&
                      viewModel.concentrations!.isNotEmpty ||
                  viewModel.siteData != null &&
                      viewModel.siteData!.isNotEmpty)) ...[
            _buildWeeklySummaryCard(context, viewModel),
            const SizedBox(height: 20),
          ],

          // 3. TODAY'S SNAPSHOT
          if (viewModel.concentrations != null &&
              viewModel.concentrations!.isNotEmpty) ...[
            _buildTodaySnapshot(context, viewModel),
            const SizedBox(height: 20),
          ],

          // 4. TOP ALLERGENS (now with trend arrows if site data available)
          if (viewModel.concentrations != null &&
              viewModel.concentrations!.isNotEmpty) ...[
            _buildTopAllergensList(context, viewModel),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  // ====== LOCATION SELECTOR ======
  Widget _buildLocationSelector(BuildContext context, HomeViewModel viewModel) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lokacija',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButton<Locations>(
                    hint: const Text('Izaberi lokaciju'),
                    value: viewModel.selectedLocation,
                    isExpanded: true,
                    underline: Container(),
                    items: viewModel.locations!
                        .map(
                          (loc) => DropdownMenuItem<Locations>(
                            value: loc,
                            child: Text(loc.name),
                          ),
                        )
                        .toList(),
                    onChanged: (loc) {
                      if (loc != null) {
                        viewModel.selectLocation(loc);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  tooltip: 'Koristi moju lokaciju',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Geolokacija će uskoro biti dostupna'),
                      ),
                    );
                  },
                  child: const Icon(Icons.location_on),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ====== WEEKLY SUMMARY CARD (with 5-tier if available) ======
  Widget _buildWeeklySummaryCard(
    BuildContext context,
    HomeViewModel viewModel,
  ) {
    // Use 5-tier from site data if available, otherwise fallback to 3-tier
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

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor, statusColor.withAlpha(179)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withAlpha(77),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      viewModel.selectedLocation!.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      viewModel.siteData != null &&
                              viewModel.siteData!.isNotEmpty
                          ? 'Nedelja ${viewModel.siteData!.first.week}'
                          : viewModel.selectedDate ?? 'N/A',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.eco, color: Colors.white, size: 32),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Kategorija: $overallStatus',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: double.parse(percentage) / 100,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$percentage% povišenih nivoa',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  // ====== TODAY'S SNAPSHOT ======
  Widget _buildTodaySnapshot(BuildContext context, HomeViewModel viewModel) {
    final typeData = _getTypeData(viewModel);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pregled po vrstama',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSnapshotColumn(
                    icon: Icons.park,
                    label: 'Drveće',
                    severity: typeData[1]?['severity'] ?? 'Nema',
                    color: typeData[1]?['color'] ?? Colors.grey,
                    allergenicityLabel:
                        typeData[1]?['allergenicityLabel'] ?? '',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSnapshotColumn(
                    icon: Icons.grass,
                    label: 'Trave',
                    severity: typeData[2]?['severity'] ?? 'Nema',
                    color: typeData[2]?['color'] ?? Colors.grey,
                    allergenicityLabel:
                        typeData[2]?['allergenicityLabel'] ?? '',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSnapshotColumn(
                    icon: Icons.eco,
                    label: 'Korovi',
                    severity: typeData[3]?['severity'] ?? 'Nema',
                    color: typeData[3]?['color'] ?? Colors.grey,
                    allergenicityLabel:
                        typeData[3]?['allergenicityLabel'] ?? '',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSnapshotColumn({
    required IconData icon,
    required String label,
    required String severity,
    required Color color,
    required String allergenicityLabel,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color.withAlpha(51), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            severity,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (allergenicityLabel.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              allergenicityLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ====== TOP ALLERGENS (with trend arrows) ======
  Widget _buildTopAllergensList(BuildContext context, HomeViewModel viewModel) {
    if (viewModel.isLoadingPollenData) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
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
        : 1;

    // Create a map of allergen ID to trend (if site data available)
    final trendMap = <int, int>{};
    if (viewModel.siteData != null) {
      for (var site in viewModel.siteData!) {
        trendMap[site.allergenId] = site.trend;
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Top 5 alergena',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(51),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "Alergijski potencijal",
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ),
                const Spacer(),
                Text(
                  "Koncentracija (ug/m³)",
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...topAllergens.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final conc = entry.value;

              final allergen = viewModel.allergens!.firstWhere(
                (a) => a.id == conc.allergenId,
                orElse: () => viewModel.allergens!.first,
              );

              final color = _getAllergenicityColor(allergen, conc.value);
              final severityLabel = _getCombinedSeverityLabel(
                allergen,
                conc.value,
              );

              // Get trend if available
              final trend = trendMap[allergen.id];
              final trendIcon = _getTrendIcon(trend);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Column(
                                children: [
                                  Text(
                                    '$index. ${allergen.localizedName}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withAlpha(51),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  allergen.allergenicityDisplayLocalized,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (trendIcon != null) ...[
                                const SizedBox(width: 4),
                                Icon(trendIcon, size: 14, color: color),
                              ],
                            ],
                          ),
                        ),
                        Text(
                          '${conc.value}',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              minHeight: 6,
                              value: conc.value / maxValue,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          severityLabel,
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
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

  //--------------------------------------------------------------------------
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

  //--------------------------------------------------------------------------
  Color _lightenColor(Color color, double factor) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + factor).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  //--------------------------------------------------------------------------
  String _getCombinedSeverityLabel(Allergen allergen, int concentration) {
    final concentrationLevel = _getSeverityLabel(concentration);
    return '$concentrationLevel ';
  }

  //--------------------------------------------------------------------------
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

  //--------------------------------------------------------------------------
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
