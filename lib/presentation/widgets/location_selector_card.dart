import 'package:flutter/material.dart';
import 'package:udahni/data/models/locations.dart';

/// Presentational card for selecting a location from a dropdown with optional "my location" action.
class LocationSelectorCard extends StatelessWidget {
  const LocationSelectorCard({
    super.key,
    required this.locations,
    this.selectedLocation,
    this.onLocationChanged,
    this.onMyLocationPressed,
    this.isMyLocationLoading = false,
  });

  final List<Locations> locations;
  final Locations? selectedLocation;
  final ValueChanged<Locations>? onLocationChanged;
  final VoidCallback? onMyLocationPressed;
  final bool isMyLocationLoading;

  @override
  Widget build(BuildContext context) {
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
                    value: selectedLocation,
                    isExpanded: true,
                    underline: Container(),
                    items: locations
                        .map(
                          (loc) => DropdownMenuItem<Locations>(
                            value: loc,
                            child: Text(loc.name),
                          ),
                        )
                        .toList(),
                    onChanged: (loc) {
                      if (loc != null) {
                        onLocationChanged?.call(loc);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  tooltip: 'Koristi moju lokaciju',
                  onPressed: isMyLocationLoading ? null : onMyLocationPressed,
                  child: isMyLocationLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Icon(Icons.location_on),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
