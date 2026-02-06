import 'package:alergeni/core/theme/app_theme.dart';
import 'package:alergeni/data/models/allergen.dart';
import 'package:alergeni/data/models/allergen_types.dart';
import 'package:alergeni/data/models/concentrations.dart';
import 'package:alergeni/data/models/locations.dart';
import 'package:alergeni/data/models/pollens.dart';
import 'package:alergeni/data/repositories/pollen_repository.dart';
import 'package:alergeni/presentation/widgets/allergen_card.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

//--------------------------------------------------------------------------
class _HomeScreenState extends State<HomeScreen> {
  final PollenRepository _pollenRepository = PollenRepository();

  List<Locations>? _locations;
  bool _isLoading = true;
  String? _errorMessage;
  Locations? _selectedLocation;
  List<Allergen>? _allergens;
  List<AllergenTypes>? _allergenTypes;
  List<Concentrations>? _concentrations;
  bool _isLoadingPollenData = false;
  String? selectedDate;
  bool _hasShownOffSeasonMessage = false;
  DateTime? _pollenDate;

  int lowCount = 0;
  int mediumCount = 0;
  int highCount = 0;

  //--------------------------------------------------------------------------
  bool get _isShowingHistoricalData {
    if (_pollenDate == null) return false;
    final now = DateTime.now();
    final difference = now.difference(_pollenDate!).inDays;
    return difference > 7;
  }

  //--------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _fetchLocations();
    _fetchAllergens();
    _fetchAllergenTypes();
    _checkOffSeason();
  }

  //--------------------------------------------------------------------------
  Future<void> _fetchLocations() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final locations = await _pollenRepository.fetchLocations();

      setState(() {
        _locations = locations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  //--------------------------------------------------------------------------
  Future<void> _fetchAllergens() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final allergens = await _pollenRepository.fetchAllergens();

      setState(() {
        _allergens = allergens;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  //--------------------------------------------------------------------------
  Future<void> _fetchAllergenTypes() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final allergenTypes = await _pollenRepository.fetchAllergenTypes();

      setState(() {
        _allergenTypes = allergenTypes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  //--------------------------------------------------------------------------
  void _checkOffSeason() {
    final now = DateTime.now();
    final isOffSeason = (now.month >= 10 || now.month <= 1);

    if (isOffSeason && !_hasShownOffSeasonMessage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showOffSeasonDialog();
      });
    }
  }

  //--------------------------------------------------------------------------
  void _showOffSeasonDialog() {
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
              setState(() {
                _hasShownOffSeasonMessage = true;
              });
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  //--------------------------------------------------------------------------
  Future<void> _fetchPollenData() async {
    if (_selectedLocation == null) return;

    try {
      setState(() {
        _isLoadingPollenData = true;
        _errorMessage = null;
      });

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
        setState(() {
          _concentrations = null;
          selectedDate = null;
          _isLoadingPollenData = false;
        });
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
        setState(() {
          _concentrations = null;
          selectedDate = null;
          _isLoadingPollenData = false;
        });
        return;
      }

      // Step 3: Count severity levels
      lowCount = 0;
      mediumCount = 0;
      highCount = 0;

      for (var conc in concentrations) {
        if (conc.value >= 1 && conc.value <= 10) {
          lowCount++;
        } else if (conc.value >= 11 && conc.value <= 50) {
          mediumCount++;
        } else if (conc.value > 50) {
          highCount++;
        }
      }

      // Step 5: Update state with all data
      setState(() {
        _concentrations = concentrations;
        _pollenDate = pollen!.date;
        selectedDate =
            '${pollen.date.day.toString().padLeft(2, '0')}.${pollen.date.month.toString().padLeft(2, '0')}.${pollen.date.year}.';
        _isLoadingPollenData = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoadingPollenData = false;
      });
    }
  }

  //--------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Udahni'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _buildBody(),
    );
  }

  //--------------------------------------------------------------------------
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Greška: $_errorMessage', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchLocations,
              child: const Text('Pokušaj ponovo'),
            ),
          ],
        ),
      );
    }

    if (_locations == null || _locations!.isEmpty) {
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
            value: _selectedLocation,
            isExpanded: true,
            items: _locations!
                .map(
                  (loc) => DropdownMenuItem<Locations>(
                    value: loc,
                    child: Text(loc.name),
                  ),
                )
                .toList(),
            onChanged: (loc) {
              setState(() {
                _selectedLocation = loc;
              });
              _fetchPollenData();
            },
          ),
          const SizedBox(height: 16.0),

          // Date display
          if (selectedDate != null)
            Text(
              _isShowingHistoricalData
                  ? 'Poslednji podaci su za datum: $selectedDate'
                  : 'Podaci za datum: $selectedDate',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _isShowingHistoricalData ? Colors.grey[600] : null,
                fontStyle: _isShowingHistoricalData ? FontStyle.italic : null,
              ),
            ),

          // Summary cards
          if (_concentrations != null && _concentrations!.isNotEmpty) ...[
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
                    lowCount,
                    AppTheme.severityLow,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard(
                    'Srednji',
                    mediumCount,
                    AppTheme.severityMedium,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard(
                    'Visok',
                    highCount,
                    AppTheme.severityHigh,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
          ],

          // Allergen list
          Expanded(
            child: _selectedLocation == null
                ? const Center(
                    child: Text('Izaberite lokaciju za prikaz podataka.'),
                  )
                : _buildAllergenList(),
          ),
        ],
      ),
    );
  }

  //--------------------------------------------------------------------------
  Widget _buildSummaryCard(String title, int count, Color color) {
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
  Widget _buildAllergenList() {
    if (_isLoadingPollenData) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_concentrations == null || _concentrations!.isEmpty) {
      return const Center(
        child: Text('Nema aktivnih koncentracija polena za izabranu lokaciju.'),
      );
    }

    final activeConcentrations = _concentrations!
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
      final allergen = _allergens!.firstWhere((a) => a.id == conc.allergenId);
      final typeId = allergen.type;
      groupedByType.putIfAbsent(typeId, () => []).add(conc);
    }

    return RefreshIndicator(
      onRefresh: _fetchPollenData,
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
                  _allergenTypes
                      ?.firstWhere(
                        (t) => t.id == typeId,
                        orElse: () => AllergenTypes(id: typeId, name: 'Ostalo'),
                      )
                      .name ??
                  'Ostalo';

              return ExpansionTile(
                title: Text(
                  '$typeName (${concentrationsForType.length})',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                initiallyExpanded:
                    true, // Or false if you want collapsed by default
                children: concentrationsForType.map((conc) {
                  final allergen = _allergens!.firstWhere(
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
