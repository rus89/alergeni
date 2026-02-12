import 'package:flutter/material.dart';

/// Presentational card showing weekly pollen summary: location, risk category, and percentage of elevated levels.
class WeeklySummaryCard extends StatelessWidget {
  const WeeklySummaryCard({
    super.key,
    required this.locationName,
    required this.overallStatus,
    required this.statusColor,
    required this.weekOrDateLabel,
    required this.isShowingHistoricalData,
    required this.percentage,
  });

  final String locationName;
  final String overallStatus;
  final Color statusColor;
  final String weekOrDateLabel;
  final bool isShowingHistoricalData;
  final String percentage;

  @override
  Widget build(BuildContext context) {
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
                      'Nedeljni pregled',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      locationName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          weekOrDateLabel,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                        if (isShowingHistoricalData) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.history,
                                  size: 12,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Istorijski podaci',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.eco, color: Colors.white, size: 32),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Ukupna kategorija rizika: $overallStatus',
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
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.white70),
          ),
          Text(
            'Udeo dana sa povišenim koncentracijama u ovoj nedelji.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white54,
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }
}
