import 'package:flutter/material.dart';

//--------------------------------------------------------------------------
class PollenStatusCard extends StatelessWidget {
  final String locationName;
  final String? locationDescription;
  final String date;
  final String pollenOverallStatus;
  final Color statusColor;
  final bool isHistorical;

  const PollenStatusCard({
    super.key,
    required this.locationName,
    this.locationDescription,
    required this.date,
    required this.pollenOverallStatus,
    required this.statusColor,
    this.isHistorical = false,
  });

  //--------------------------------------------------------------------------
  Color _getDarkerShade(Color color) {
    final hsl = HSLColor.fromColor(color);
    final darkerHsl = hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0));
    return darkerHsl.toColor();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor, _getDarkerShade(statusColor)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withAlpha(77), // 30% opacity
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              const Icon(Icons.eco, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                'Stanje polena',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withAlpha(
                    230,
                  ), // Slightly less than full opacity
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Overall status - big text
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                pollenOverallStatus,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),

          // Location info
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  locationName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          if (locationDescription != null &&
              locationDescription!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(
                locationDescription!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Date info
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(
                isHistorical ? 'Poslednji podaci: $date' : date,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  fontStyle: isHistorical ? FontStyle.italic : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
