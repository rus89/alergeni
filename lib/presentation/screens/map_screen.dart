import 'package:alergeni/data/models/locations.dart';
import 'package:alergeni/data/repositories/pollen_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

//--------------------------------------------------------------------------
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

//--------------------------------------------------------------------------
class _MapScreenState extends State<MapScreen> {
  final PollenRepository _pollenRepository = PollenRepository();
  final MapController _mapController = MapController();

  List<Locations>? _locations;
  bool _isLoading = true;
  String? _errorMessage;

  //--------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _fetchLocations();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa mernih stanica')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text('Greška: $_errorMessage'))
          : _locations == null || _locations!.isEmpty
          ? const Center(child: Text('Nema dostupnih lokacija.'))
          : _buildMapView(),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'zoom_in',
            mini: true,
            onPressed: () {
              _mapController.move(
                _mapController.camera.center,
                _mapController.camera.zoom + 1,
              );
            },
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'zoom_out',
            mini: true,
            onPressed: () {
              _mapController.move(
                _mapController.camera.center,
                _mapController.camera.zoom - 1,
              );
            },
            child: const Icon(Icons.remove),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'recenter',
            mini: true,
            onPressed: () {
              _mapController.move(const LatLng(44.0165, 21.0059), 7.0);
            },
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            // Center on Serbia
            initialCenter: const LatLng(44.0165, 21.0059),
            initialZoom: 7.0,
            minZoom: 6.5,
            maxZoom: 18.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.alergeni',
              maxZoom: 19,
            ),
            MarkerLayer(
              markers: _locations!.map((location) {
                return Marker(
                  point: LatLng(
                    double.tryParse(location.latitude) ?? 0.0,
                    double.tryParse(location.longitude) ?? 0.0,
                  ),
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => _showLocationInfo(location),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red, // or AppTheme.primaryGreen
                      size: 40,
                    ),
                  ),
                );
              }).toList(),
            ),

            // MarkerClusterLayerWidget(
            //   options: MarkerClusterLayerOptions(
            //     maxClusterRadius: 80,
            //     size: const Size(50, 50),
            //     markers: markers,
            //     builder: (context, markers) {
            //       // Custom cluster builder
            //       return Container(
            //         decoration: BoxDecoration(
            //           shape: BoxShape.circle,
            //           color: Colors.blue.shade600,
            //           border: Border.all(color: Colors.white, width: 3),
            //         ),
            //         child: Center(
            //           child: Text(
            //             markers.length.toString(),
            //             style: const TextStyle(
            //               color: Colors.white,
            //               fontWeight: FontWeight.bold,
            //               fontSize: 16,
            //             ),
            //           ),
            //         ),
            //       );
            //     },
            //   ),
            // ),
          ],
        ),
        // // Legend
        // Positioned(bottom: 20, left: 20, child: _buildLegend()),
        // // Filters card (floating)
        // Positioned(
        //   top: 10,
        //   left: 10,
        //   right: 10,
        //   child: Card(
        //     shape: RoundedRectangleBorder(
        //       borderRadius: BorderRadius.circular(12),
        //     ),
        //     elevation: 4,
        //     child: Padding(
        //       padding: const EdgeInsets.all(12),
        //       child: Column(
        //         mainAxisSize: MainAxisSize.min,
        //         children: [
        //           DropdownButtonFormField<int>(
        //             initialValue: state.selectedYear,
        //             decoration: const InputDecoration(
        //               labelText: 'Izaberite godinu',
        //               prefixIcon: Icon(Icons.calendar_today),
        //               border: OutlineInputBorder(),
        //               isDense: true,
        //             ),
        //             items: state.availableYears.map((year) {
        //               return DropdownMenuItem(
        //                 value: year,
        //                 child: Text(year.toString()),
        //               );
        //             }).toList(),
        //             onChanged: (year) async {
        //               if (year == null) return;
        //               setState(() => _isLoading = true);
        //               ref.read(trafficProvider.notifier).setYear(year);
        //               await ref
        //                   .read(trafficProvider.notifier)
        //                   .loadAccidents();
        //               if (mounted) setState(() => _isLoading = false);
        //             },
        //           ),
        //           const SizedBox(height: 8),
        //           DropdownButtonFormField<String?>(
        //             initialValue: state.selectedDept,
        //             decoration: const InputDecoration(
        //               labelText: 'Izaberite policijsku upravu',
        //               prefixIcon: Icon(Icons.location_city),
        //               border: OutlineInputBorder(),
        //               isDense: true,
        //             ),
        //             items: [
        //               const DropdownMenuItem(
        //                 value: null,
        //                 child: Text('Sve policijske uprave'),
        //               ),
        //               ...state.departments.map(
        //                 (dept) => DropdownMenuItem(
        //                   value: dept,
        //                   child: Text(dept),
        //                 ),
        //               ),
        //             ],
        //             onChanged: (dept) async {
        //               setState(() => _isLoading = true);
        //               ref
        //                   .read(trafficProvider.notifier)
        //                   .setDepartment(dept);
        //               await ref
        //                   .read(trafficProvider.notifier)
        //                   .loadAccidents();
        //               if (mounted) setState(() => _isLoading = false);
        //             },
        //           ),
        //         ],
        //       ),
        //     ),
        //   ),
        // ),
      ],
    );
  }

  void _showLocationInfo(Locations location) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(location.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Lat: ${location.latitude}, Lng: ${location.longitude}'),
          ],
        ),
      ),
    );
  }
}
