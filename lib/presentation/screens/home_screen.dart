import 'package:alergeni/core/theme/app_theme.dart';
import 'package:alergeni/data/models/allergen_types.dart';
import 'package:alergeni/data/models/concentrations.dart';
import 'package:alergeni/data/models/locations.dart';
import 'package:alergeni/presentation/viewmodels/home_view_model.dart';
import 'package:alergeni/presentation/widgets/allergen_card.dart';
import 'package:alergeni/presentation/widgets/pollen_status_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  //--------------------------------------------------------------------------
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
              context.read<HomeViewModel>().hasShownOffSeasonMessage = true;
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  //--------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<HomeViewModel>();
    if (viewModel.shouldShowOffSeasonDialog) {
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
      ),
      body: _buildBody(context, context.watch<HomeViewModel>()),
    );
  }

  //--------------------------------------------------------------------------
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

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Location dropdown
          DropdownButton<Locations>(
            hint: const Text('Izaberi lokaciju'),
            value: viewModel.selectedLocation,
            isExpanded: true,
            items: viewModel.locations!
                .map(
                  (loc) => DropdownMenuItem<Locations>(
                    value: loc,
                    child: Text(loc.name),
                  ),
                )
                .toList(),
            onChanged: (loc) {
              viewModel.selectLocation(loc!);
            },
          ),
          const SizedBox(height: 16.0),

          // hero card display
          if (viewModel.selectedLocation != null &&
              viewModel.selectedDate != null)
            PollenStatusCard(
              locationName: viewModel.selectedLocation!.name,
              locationDescription: viewModel.selectedLocation!.description,
              date: viewModel.selectedDate!,
              pollenOverallStatus: viewModel.getOverallStatus(),
              statusColor: viewModel.getOverallStatusColor(),
              isHistorical: viewModel.isShowingHistoricalData,
            ),
          const SizedBox(height: 16.0),
          // Date display
          if (viewModel.selectedDate != null)
            Text(
              viewModel.isShowingHistoricalData
                  ? 'Poslednji podaci su za datum: ${viewModel.selectedDate}'
                  : 'Podaci za datum: ${viewModel.selectedDate}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: viewModel.isShowingHistoricalData
                    ? Colors.grey[600]
                    : null,
                fontStyle: viewModel.isShowingHistoricalData
                    ? FontStyle.italic
                    : null,
              ),
            ),
          // Summary cards
          if (viewModel.concentrations != null &&
              viewModel.concentrations!.isNotEmpty) ...[
            const SizedBox(height: 16.0),
            const Text(
              'Pregled nivoa koncentracija:',
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Nizak',
                    viewModel.lowCount,
                    AppTheme.severityLow,
                    context,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard(
                    'Srednji',
                    viewModel.mediumCount,
                    AppTheme.severityMedium,
                    context,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard(
                    'Visok',
                    viewModel.highCount,
                    AppTheme.severityHigh,
                    context,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
          ],

          // Allergen list
          Expanded(
            child: viewModel.selectedLocation == null
                ? const Center(
                    child: Text('Izaberite lokaciju za prikaz podataka.'),
                  )
                : _buildAllergenList(viewModel, context),
          ),
        ],
      ),
    );
  }

  //--------------------------------------------------------------------------
  Widget _buildSummaryCard(
    String title,
    int count,
    Color color,
    BuildContext context,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  //--------------------------------------------------------------------------
  Widget _getTypeIcon(int typeId) {
    switch (typeId) {
      case 1:
        return const Icon(Icons.nature, color: Colors.green);
      case 2:
        return const Icon(Icons.grass, color: Colors.lightGreen);
      case 3:
        return const Icon(Icons.local_florist, color: Colors.orange);
      default:
        return const Icon(Icons.all_inclusive, color: Colors.grey);
    }
  }

  //--------------------------------------------------------------------------
  Widget _buildAllergenList(HomeViewModel viewModel, BuildContext context) {
    if (viewModel.isLoadingPollenData) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.concentrations == null || viewModel.concentrations!.isEmpty) {
      return const Center(
        child: Text('Nema aktivnih koncentracija polena za izabranu lokaciju.'),
      );
    }

    final activeConcentrations = viewModel.concentrations!
        .where((conc) => conc.value > 0)
        .toList();

    activeConcentrations.sort((a, b) => b.value.compareTo(a.value));

    if (activeConcentrations.isEmpty) {
      return const Center(
        child: Text('Nema aktivnih koncentracija polena za izabranu lokaciju.'),
      );
    }

    final Map<int, List<Concentrations>> groupedByType = {};
    for (var conc in activeConcentrations) {
      final allergen = viewModel.allergens!.firstWhere(
        (a) => a.id == conc.allergenId,
      );
      final typeId = allergen.type;
      groupedByType.putIfAbsent(typeId, () => []).add(conc);
    }

    return RefreshIndicator(
      onRefresh: viewModel.fetchPollenData,
      child: SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(), // Important! Allows pull even when content fits
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Text(
                'Aktivni alergeni: ${activeConcentrations.length}',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: Colors.grey[600]),
              ),
            ),

            // Group concentrations by allergen type
            ...groupedByType.entries.map((entry) {
              final typeId = entry.key;
              final concentrationsForType = entry.value;

              // Find the type name
              final typeName =
                  viewModel.allergenTypes
                      ?.firstWhere(
                        (t) => t.id == typeId,
                        orElse: () => AllergenTypes(id: typeId, name: 'Ostalo'),
                      )
                      .name ??
                  'Ostalo';

              return ExpansionTile(
                // add Icon before type name based on typeId (e.g. tree, grass, weed)
                leading: _getTypeIcon(typeId),
                title: Text(
                  '$typeName (${concentrationsForType.length})',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                initiallyExpanded:
                    true, // Or false if you want collapsed by default
                children: concentrationsForType.map((conc) {
                  final allergen = viewModel.allergens!.firstWhere(
                    (a) => a.id == conc.allergenId,
                  );
                  return AllergenCard(
                    allergen: allergen,
                    concentration: conc.value,
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }
}
