import 'package:flutter/material.dart';

//--------------------------------------------------------------------------
class OffSeasonMessage extends StatelessWidget {
  final String? lastDataDate;
  final VoidCallback? onViewHistorical;

  const OffSeasonMessage({super.key, this.lastDataDate, this.onViewHistorical});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.nature_outlined, size: 80, color: Colors.green[300]),
            const SizedBox(height: 24.0),
            Text(
              'Sezona praćenja polena je završena.',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12.0),
            Text(
              "Novi ciklus praćenja polena počinje u Februaru naredne godine.",
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (lastDataDate != null) ...[
              const SizedBox(height: 8.0),
              Text(
                "Poslednji podaci su od: $lastDataDate",
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
            if (onViewHistorical != null) ...[
              const SizedBox(height: 24.0),
              OutlinedButton.icon(
                onPressed: onViewHistorical,
                icon: const Icon(Icons.history),
                label: const Text('Pogledaj istorijske podatke'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
