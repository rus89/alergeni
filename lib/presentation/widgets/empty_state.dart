import 'package:flutter/material.dart';

/// Shared empty state widget for consistent UX across Home and Map screens.
class EmptyState extends StatelessWidget {
  /// Short title (e.g. "Nema dostupnih lokacija").
  final String title;

  /// Optional longer explanation.
  final String? subtitle;

  /// Optional icon; defaults to [Icons.inbox_outlined].
  final IconData? icon;

  const EmptyState({super.key, required this.title, this.subtitle, this.icon});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = colorScheme.onSurfaceVariant;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon ?? Icons.inbox_outlined, color: iconColor, size: 48),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
