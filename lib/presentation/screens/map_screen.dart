import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:udahni/core/helpers/allergen_type_helper.dart';
import 'package:udahni/core/helpers/severity_helper.dart';
import 'package:udahni/data/models/locations.dart';
import 'package:udahni/presentation/viewmodels/map_view_model.dart';
import 'package:udahni/presentation/widgets/empty_state.dart';
import 'package:udahni/presentation/widgets/error_state.dart';
import 'package:udahni/presentation/widgets/loading_state.dart';

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
          : _MapView(
              locations: mapViewModel.locations!,
              mapViewModel: mapViewModel,
            ),
    );
  }
}

//--------------------------------------------------------------------------
class _MapView extends StatefulWidget {
  final List<Locations> locations;
  final MapViewModel mapViewModel;

  const _MapView({required this.locations, required this.mapViewModel});

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
              userAgentPackageName: 'com.serbiaOpenData.udahni',
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
                    child: Icon(
                      Icons.location_on,
                      color: widget.mapViewModel.getPinColorForLocation(
                        location.id,
                      ),
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
          _buildSeverityLegend(context),
          const SizedBox(height: 10),
          _buildTrendLegend(context),
        ],
      ),
    );
  }

  //----------------------------------------------------------------------------
  Widget _buildSeverityLegend(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipovi i potencijal alergena',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        _buildTypeSeverityRow(
          context: context,
          typeLabel: 'Drveće',
          typeColor: AllergenTypeHelper.getColorForType(
            AllergenTypeHelper.treeTypeId,
          ),
          severityLabels: const ['Nizak', 'Srednji', 'Visok'],
        ),
        const SizedBox(height: 4),
        _buildTypeSeverityRow(
          context: context,
          typeLabel: 'Trave',
          typeColor: AllergenTypeHelper.getColorForType(
            AllergenTypeHelper.grassTypeId,
          ),
          severityLabels: const ['Srednji'],
        ),
        const SizedBox(height: 4),
        _buildTypeSeverityRow(
          context: context,
          typeLabel: 'Korovi',
          typeColor: AllergenTypeHelper.getColorForType(
            AllergenTypeHelper.weedTypeId,
          ),
          severityLabels: const ['Nizak', 'Srednji', 'Visok'],
        ),
      ],
    );
  }

  //----------------------------------------------------------------------------
  Widget _buildTypeSeverityRow({
    required BuildContext context,
    required String typeLabel,
    required Color typeColor,
    required List<String> severityLabels,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(color: typeColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 210),
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              Text(
                '$typeLabel:',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              ...severityLabels.map(
                (label) => _buildSeverityChip(context, label),
              ),
            ],
          ),
        ),
      ],
    );
  }

  //----------------------------------------------------------------------------
  Widget _buildSeverityChip(BuildContext context, String label) {
    final color = switch (label) {
      'Nizak' => SeverityHelper.allergenicityBaseColor(1),
      'Srednji' => SeverityHelper.allergenicityBaseColor(2),
      'Visok' => SeverityHelper.allergenicityBaseColor(3),
      _ => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withAlpha(36),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  //----------------------------------------------------------------------------
  Widget _buildTrendLegend(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Boja markera (trend)',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        _buildLegendItem(
          widget.mapViewModel.getPinColorForTrendValue(1),
          'Opadajući',
          context,
        ),
        const SizedBox(height: 4),
        _buildLegendItem(
          widget.mapViewModel.getPinColorForTrendValue(2),
          'Stabilan',
          context,
        ),
        const SizedBox(height: 4),
        _buildLegendItem(
          widget.mapViewModel.getPinColorForTrendValue(3),
          'Rastući',
          context,
        ),
      ],
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
    final mapViewModel = context.read<MapViewModel>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _LocationInfoSheet(
        location: location,
        loadSummary: () =>
            mapViewModel.getLocationSummary(locationId: location.id),
      ),
    );
  }
}

class _LocationInfoSheet extends StatefulWidget {
  final Locations location;
  final Future<MapLocationSummary> Function() loadSummary;

  const _LocationInfoSheet({required this.location, required this.loadSummary});

  @override
  State<_LocationInfoSheet> createState() => _LocationInfoSheetState();
}

class _LocationInfoSheetState extends State<_LocationInfoSheet> {
  late Future<MapLocationSummary> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = widget.loadSummary();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.location.name, style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Koordinate: ${widget.location.latitude.toStringAsFixed(4)}, '
              '${widget.location.longitude.toStringAsFixed(4)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.location.description.trim().isNotEmpty
                  ? widget.location.description
                  : 'Opis lokacije nije dostupan.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<MapLocationSummary>(
              future: _summaryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        ),
                        SizedBox(width: 10),
                        Text('Učitavanje sažetka za stanicu...'),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sažetak trenutno nije dostupan.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _summaryFuture = widget.loadSummary();
                          });
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Pokušaj ponovo'),
                      ),
                    ],
                  );
                }

                final summary = snapshot.data;
                if (summary == null || !summary.hasData) {
                  return Text(
                    'Nema detaljnih podataka za ovu stanicu u ovom trenutku.',
                    style: theme.textTheme.bodyMedium,
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: summary.riskColor.withAlpha(36),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Rizik: ${summary.riskLabel}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: summary.riskColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          summary.trendIcon,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          summary.trendLabel,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    if (summary.week != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Nedelja: ${summary.week}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
