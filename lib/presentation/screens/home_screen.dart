import 'package:alergeni/data/models/allergen.dart';
import 'package:alergeni/data/models/concentrations.dart';
import 'package:alergeni/data/models/locations.dart';
import 'package:alergeni/data/models/pollens.dart';
import 'package:alergeni/data/repositories/pollen_repository.dart';
import 'package:alergeni/presentation/widgets/allergen_card.dart';
import 'package:alergeni/presentation/widgets/off_season_message.dart';
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
  Pollens? _pollen;
  List<Concentrations>? _concentrations;
  bool _isLoadingPollenData = false;
  String? selectedDate;

  //--------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _fetchLocations();
    _fetchAllergens();
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
  Future<void> _fetchPollenData() async {
    if (_selectedLocation == null) return;

    try {
      setState(() {
        _isLoadingPollenData = true;
        _errorMessage = null;
      });

      // Step 1: Fetch pollens for location
      final pollensResponse = await _pollenRepository.fetchPollensByLocation(
        _selectedLocation!.id,
      );

      // Step 2: Check if we have results
      if (pollensResponse.results.isEmpty) {
        // No data - off season or no data for location
        setState(() {
          _pollen = null;
          _concentrations = null;
          selectedDate = null;
          _isLoadingPollenData = false;
        });
        return;
      }

      // Step 3: Get the first (most recent) pollen record
      final sortedPollens = pollensResponse.results.toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      final pollen = sortedPollens.first;

      // Step 4: Fetch concentrations for this pollen record
      final concentrations = await _pollenRepository.fetchConcentrationsByIds(
        pollen.concentrationIds,
      );

      // Step 5: Update state with all data
      setState(() {
        _pollen = pollen;
        _concentrations = concentrations;
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
              'Podaci za datum: $selectedDate',
              style: Theme.of(context).textTheme.bodyMedium,
            ),

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
  Widget _buildAllergenList() {
    if (_isLoadingPollenData) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_concentrations == null || _concentrations!.isEmpty) {
      return const OffSeasonMessage();
    }

    final activeConcentrations = _concentrations!
        .where((conc) => conc.value > 0)
        .toList();

    if (activeConcentrations.isEmpty) {
      return const Center(
        child: Text('Nema aktivnih koncentracija polena za izabranu lokaciju.'),
      );
    }

    return ListView.builder(
      itemCount: activeConcentrations.length,
      itemBuilder: (context, index) {
        final concentration = activeConcentrations[index];
        final allergen = _allergens!.firstWhere(
          (allergen) => allergen.id == concentration.allergenId,
        );

        return AllergenCard(
          allergen: allergen,
          concentration: concentration.value,
        );
      },
    );
  }
}
