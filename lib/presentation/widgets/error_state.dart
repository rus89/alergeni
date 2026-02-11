import 'package:flutter/material.dart';

/// Shared error state widget for consistent UX across Home and Map screens.
class ErrorState extends StatelessWidget {
  /// Error message to display (e.g. from API or generic "Došlo je do greške").
  final String message;

  /// Optional callback when user taps retry. If null, retry button is hidden.
  final VoidCallback? onRetry;

  const ErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final errorColor = colorScheme.error;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: errorColor, size: 48),
            const SizedBox(height: 16),
            Text(
              message.startsWith('Greška: ') ? message : 'Greška: $message',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Pokušaj ponovo'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
