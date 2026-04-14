// ABOUTME: Home tab content — daily pollen snapshot with location selector and allergen cards.
// ABOUTME: Handles off-season dialog and shows a first-visit hint card.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:udahni/core/errors/app_error.dart';
import 'package:udahni/core/helpers/level_helper.dart';
import 'package:udahni/core/helpers/severity_helper.dart';
import 'package:udahni/core/services/onboarding_service.dart';
import 'package:udahni/presentation/viewmodels/home_view_model.dart';
import 'package:udahni/presentation/viewmodels/personal_allergen_view_model.dart';
import 'package:udahni/presentation/widgets/empty_state.dart';
import 'package:udahni/presentation/widgets/error_state.dart';
import 'package:udahni/presentation/widgets/hint_card.dart';
import 'package:udahni/presentation/widgets/loading_state.dart';
import 'package:udahni/presentation/widgets/location_selector_card.dart';
import 'package:udahni/presentation/widgets/today_snapshot_card.dart';
import 'package:udahni/presentation/widgets/top_allergens_card.dart';
import 'package:udahni/presentation/widgets/weekly_summary_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _sectionSpacing = 16;
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final viewModel = context.read<HomeViewModel>();
      if (viewModel.shouldShowOffSeasonDialog) {
        _showOffSeasonDialog(context);
        viewModel.hasShownOffSeasonMessage = true;
      }
      final service = context.read<OnboardingService>();
      final visited = await service.hasVisitedScreen(OnboardingService.homeKey);
      if (!mounted) return;
      if (!visited) setState(() => _showHint = true);
    });
  }

  void _dismissHint() async {
    final service = context.read<OnboardingService>();
    await service.markScreenVisited(OnboardingService.homeKey);
    if (mounted) setState(() => _showHint = false);
  }

  void _showOffSeasonDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('Obaveštenje o sezoni'),
        content: const Text(
          'Sezona praćenja polena je završena.\n\n'
          'Novi ciklus praćenja počinje u februaru naredne godine.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('U redu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();

    return Stack(
      children: [
        _buildContent(context, viewModel),
        if (_showHint)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: HintCard(
              message:
                  'Odaberite lokaciju koja vam je najbliža i pratite nivoe '
                  'ozbiljnosti peludi za svaki dan.',
              onDismiss: _dismissHint,
            ),
          ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, HomeViewModel viewModel) {
    if (viewModel.isLoading) {
      return const LoadingState();
    }

    if (viewModel.error != null) {
      return ErrorState(
        error: viewModel.error!,
        onRetry: viewModel.loadInitialData,
      );
    }

    if (viewModel.locations == null || viewModel.locations!.isEmpty) {
      return const EmptyState(title: 'Nema dostupnih lokacija.');
    }

    final isInitialPollenDataLoading =
        viewModel.isLoadingPollenData &&
        viewModel.selectedLocation != null &&
        viewModel.concentrations == null &&
        (viewModel.siteData == null || viewModel.siteData!.isEmpty);
    if (isInitialPollenDataLoading) {
      return const LoadingState(
        message: 'Učitavanje podataka za izabranu lokaciju...',
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.fetchPollenData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LocationSelectorCard(
              locations: viewModel.locations!,
              selectedLocation: viewModel.selectedLocation,
              isMyLocationLoading: viewModel.isLocatingNearestLocation,
              onLocationChanged: viewModel.selectLocation,
              onMyLocationPressed: () async {
                try {
                  final nearestLocation =
                      await viewModel.selectNearestLocationFromDevice();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Izabrana je najbliža lokacija: ${nearestLocation.name}',
                      ),
                    ),
                  );
                } catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        error is AppError
                            ? error.userMessage
                            : error
                                  .toString()
                                  .replaceFirst('Exception: ', ''),
                      ),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: _sectionSpacing),

            if (viewModel.selectedLocation != null &&
                (viewModel.concentrations != null &&
                        viewModel.concentrations!.isNotEmpty ||
                    viewModel.siteData != null &&
                        viewModel.siteData!.isNotEmpty)) ...[
              _buildWeeklySummaryCard(context, viewModel),
              const SizedBox(height: _sectionSpacing),
            ],

            if (viewModel.concentrations != null &&
                viewModel.concentrations!.isNotEmpty) ...[
              TodaySnapshotCard(items: _buildSnapshotItems(viewModel)),
              const SizedBox(height: _sectionSpacing),
            ],

            if (viewModel.concentrations != null &&
                viewModel.concentrations!.isNotEmpty) ...[
              _buildTopAllergensSection(
                context,
                viewModel,
                context
                    .watch<PersonalAllergenViewModel>()
                    .selectedAllergenIds,
              ),
              const SizedBox(height: _sectionSpacing),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySummaryCard(
    BuildContext context,
    HomeViewModel viewModel,
  ) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              iconSize: 18,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Nivoi ozbiljnosti'),
                    content: const Text(
                      'Svaki nivo ozbiljnosti je označen bojom:\n\n'
                      '● Siva — nema koncentracije\n'
                      '● Zelena — nizak nivo\n'
                      '● Narandžasta — srednji nivo\n'
                      '● Crvena — visok nivo\n\n'
                      'Prikazana boja odgovara ukupnom statusu za izabranu stanicu.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('U redu'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        WeeklySummaryCard(
          locationName: viewModel.selectedLocation!.name,
          overallStatus: overallStatus,
          statusColor: statusColor,
          weekOrDateLabel: weekOrDateLabel,
          isShowingHistoricalData: viewModel.isShowingHistoricalData,
          percentage: percentage,
        ),
      ],
    );
  }

  List<SnapshotColumnItem> _buildSnapshotItems(HomeViewModel viewModel) {
    final typeData = viewModel.typeDataMap;
    return [
      SnapshotColumnItem(
        icon: Icons.park,
        label: 'Drveće',
        color: typeData[1]?.color ?? Colors.grey,
      ),
      SnapshotColumnItem(
        icon: Icons.grass,
        label: 'Trave',
        color: typeData[2]?.color ?? Colors.grey,
      ),
      SnapshotColumnItem(
        icon: Icons.eco,
        label: 'Korovi',
        color: typeData[3]?.color ?? Colors.grey,
      ),
    ];
  }

  Widget _buildTopAllergensSection(
    BuildContext context,
    HomeViewModel viewModel,
    Set<int> personalAllergenIds,
  ) {
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
      final color = SeverityHelper.allergenicityColorForConcentration(
        allergenicityIndex: allergen.allergenicityIndex,
        concentration: conc.value,
      );
      final severityLabel = SeverityHelper.concentrationLabel(conc.value);
      final trend = trendMap[allergen.id];
      final trendIcon = trend != null ? LevelHelper.trendToIcon(trend) : null;

      return TopAllergenItem(
        index: index,
        name: allergen.localizedName,
        allergenicityLabel: allergen.allergenicityDisplayLocalized,
        color: color,
        value: conc.value,
        severityLabel: severityLabel,
        trendIcon: trendIcon,
        isPersonal: personalAllergenIds.contains(allergen.id),
      );
    }).toList();

    return TopAllergensCard(
      items: items,
      maxValue: maxValue,
      showTrendHint:
          viewModel.siteData != null && viewModel.siteData!.isNotEmpty,
    );
  }
}
