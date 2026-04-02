// ABOUTME: Displays user-friendly error messages with icons based on error type.
// ABOUTME: Renders different icons and messages for network, server, and unexpected errors.

import 'package:flutter/material.dart';
import 'package:udahni/core/errors/app_error.dart';

class ErrorState extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;

  const ErrorState({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_iconForError(error), color: _colorForError(error), size: 48),
            const SizedBox(height: 16),
            Text(
              error.userMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
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

  static IconData _iconForError(AppError error) {
    return switch (error) {
      NoInternetError() => Icons.wifi_off,
      ServerError() => Icons.cloud_off,
      NotFoundError() => Icons.search_off,
      UnexpectedError() => Icons.error_outline,
    };
  }

  static Color _colorForError(AppError error) {
    return switch (error) {
      NoInternetError() => Colors.blueGrey,
      ServerError() => Colors.orange,
      NotFoundError() => Colors.grey,
      UnexpectedError() => Colors.red,
    };
  }
}
