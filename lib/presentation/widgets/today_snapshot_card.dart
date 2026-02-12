import 'package:flutter/material.dart';

/// Data for a single column in the today snapshot (e.g. Trees, Grasses, Weeds).
class SnapshotColumnItem {
  const SnapshotColumnItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;
}

/// Presentational card showing today's overview by pollen type (trees, grasses, weeds).
class TodaySnapshotCard extends StatelessWidget {
  const TodaySnapshotCard({
    super.key,
    required this.items,
  });

  /// Exactly three items: [Trees, Grasses, Weeds] in that order.
  final List<SnapshotColumnItem> items;

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
              'Današnji pregled po vrstama',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (items.isNotEmpty) ...[
                  Expanded(
                    child: _SnapshotColumn(
                      icon: items[0].icon,
                      label: items[0].label,
                      color: items[0].color,
                    ),
                  ),
                  if (items.length > 1) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SnapshotColumn(
                        icon: items[1].icon,
                        label: items[1].label,
                        color: items[1].color,
                      ),
                    ),
                  ],
                  if (items.length > 2) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SnapshotColumn(
                        icon: items[2].icon,
                        label: items[2].label,
                        color: items[2].color,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SnapshotColumn extends StatelessWidget {
  const _SnapshotColumn({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color.withAlpha(51), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
