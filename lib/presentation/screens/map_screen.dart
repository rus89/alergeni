import 'package:alergeni/core/helpers/allergen_type_helper.dart';
import 'package:alergeni/data/models/locations.dart';
import 'package:alergeni/presentation/viewmodels/map_view_model.dart';
import 'package:alergeni/presentation/widgets/empty_state.dart';
import 'package:alergeni/presentation/widgets/error_state.dart';
import 'package:alergeni/presentation/widgets/loading_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

//--------------------------------------------------------------------------
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mapViewModel = context.watch<MapViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa mernih stanica'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: mapViewModel.isLoading
          ? const LoadingState()
          : mapViewModel.errorMessage != null
          ? ErrorState(
              message: mapViewModel.errorMessage!,
              onRetry: mapViewModel.refreshLocations,
            )
          : mapViewModel.locations == null || mapViewModel.locations!.isEmpty
          ? const EmptyState(title: 'Nema dostupnih lokacija.')
          : _MapView(locations: mapViewModel.locations!),
    );
  }
}

//--------------------------------------------------------------------------
class _MapView extends StatefulWidget {
  final List<Locations> locations;

  const _MapView({required this.locations});

  @override
  State<_MapView> createState() => _MapViewState();
}

//--------------------------------------------------------------------------
class _MapViewState extends State<_MapView> {
  final MapController _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: LatLng(44.0165, 21.0059),
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
              markers: widget.locations.map((location) {
                return Marker(
                  point: LatLng(location.latitude, location.longitude),
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => _showLocationInfo(context, location),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        // Legend
        Positioned(bottom: 20, left: 16, child: _buildLegend(context)),
        _buildFloatingControls(),
      ],
    );
  }

  //--------------------------------------------------------------------------
  Widget _buildLegend(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline, size: 14),
              const SizedBox(width: 6),
              Text(
                'Legenda',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildLegendItem(
            AllergenTypeHelper.getColorForType(AllergenTypeHelper.treeTypeId),
            'Drveće',
            context,
          ),
          const SizedBox(height: 4),
          _buildLegendItem(
            AllergenTypeHelper.getColorForType(AllergenTypeHelper.grassTypeId),
            'Trave',
            context,
          ),
          const SizedBox(height: 4),
          _buildLegendItem(
            AllergenTypeHelper.getColorForType(AllergenTypeHelper.weedTypeId),
            'Korovi',
            context,
          ),
        ],
      ),
    );
  }

  //----------------------------------------------------------------------------
  Widget _buildLegendItem(Color color, String label, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  //--------------------------------------------------------------------------
  Widget _buildFloatingControls() {
    return Positioned(
      right: 16,
      bottom: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'zoom_in',
            mini: true,
            tooltip: 'Uvećaj mapu',
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
            tooltip: 'Umanji mapu',
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
            tooltip: 'Vrati početni prikaz',
            onPressed: () {
              _mapController.move(const LatLng(44.0165, 21.0059), 7.0);
            },
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }

  //--------------------------------------------------------------------------
  void _showLocationInfo(BuildContext context, Locations location) {
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
