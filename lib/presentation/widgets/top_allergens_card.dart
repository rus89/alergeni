// ABOUTME: Card showing top 5 allergens ranked by concentration with trend indicators.
// ABOUTME: Highlights personal allergens and displays severity color bars.

import 'package:flutter/material.dart';
import 'package:udahni/presentation/widgets/loading_state.dart';

/// Data for a single row in the top allergens list.
class TopAllergenItem {
  const TopAllergenItem({
    required this.index,
    required this.name,
    required this.allergenicityLabel,
    required this.color,
    required this.value,
    required this.severityLabel,
    this.trendIcon,
    this.isPersonal = false,
  });

  final int index;
  final String name;
  final String allergenicityLabel;
  final Color color;
  final int value;
  final String severityLabel;
  final IconData? trendIcon;
  final bool isPersonal;
}

/// Presentational card showing top 5 allergens with concentration and optional trend.
class TopAllergensCard extends StatelessWidget {
  const TopAllergensCard({
    super.key,
    required this.items,
    required this.maxValue,
    this.showTrendHint = false,
  });

  final List<TopAllergenItem> items;
  final double maxValue;
  final bool showTrendHint;

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
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Top 5 alergena',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withAlpha(51),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Alergijski potencijal',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Koncentracija (µg/m³)',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ),
            if (showTrendHint) ...[
              const SizedBox(height: 6),
              Text(
                'Trend (↑ rastući, → stabilan, ↓ opadajući) u odnosu na prethodni period.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 16),
            ...items.map(
              (item) => _TopAllergenRow(item: item, maxValue: maxValue),
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading state for the top allergens card (e.g. while pollen data is fetching).
class TopAllergensCardLoading extends StatelessWidget {
  const TopAllergensCardLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(padding: EdgeInsets.all(16), child: LoadingState()),
    );
  }
}

class _TopAllergenRow extends StatelessWidget {
  const _TopAllergenRow({required this.item, required this.maxValue});

  final TopAllergenItem item;
  final double maxValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(8),
      decoration: item.isPersonal
          ? BoxDecoration(
              color: item.color.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
              border: Border(
                left: BorderSide(color: item.color, width: 3),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (item.isPersonal) ...[
                      Icon(Icons.person, size: 14, color: item.color),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      '${item.index}. ${item.name}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: item.color.withAlpha(51),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.allergenicityLabel,
                        style: TextStyle(
                          fontSize: 9,
                          color: item.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (item.trendIcon != null) ...[
                      const SizedBox(width: 4),
                      Icon(item.trendIcon, size: 14, color: item.color),
                    ],
                  ],
                ),
              ),
              Text(
                '${item.value}',
                style: TextStyle(
                  color: item.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: item.value / maxValue,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(item.color),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item.severityLabel,
                style: TextStyle(
                  color: item.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
