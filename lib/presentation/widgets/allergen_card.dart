import 'package:alergeni/core/theme/app_theme.dart';
import 'package:alergeni/data/models/allergen.dart';
import 'package:flutter/material.dart';

class AllergenCard extends StatelessWidget {
  final Allergen allergen;
  final int concentration;

  const AllergenCard({
    super.key,
    required this.allergen,
    required this.concentration,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getSeverityColor(),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16.0),

            // Allergen info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    allergen.localizedName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    allergen.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    _getSeverityText(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _getSeverityColor(),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Concentration value
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 12.0,
              ),
              decoration: BoxDecoration(
                color: _getSeverityColor().withAlpha(25),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                concentration.toString(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: _getSeverityColor(),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //--------------------------------------------------------------------------
  Color _getSeverityColor() {
    // Based on allergenicity index from API
    switch (allergen.allergenicityIndex) {
      case 1: // mild
        return AppTheme.severityLow;
      case 2: // moderate
        return AppTheme.severityMedium;
      case 3: // severe
        return AppTheme.severityHigh;
      default:
        return AppTheme.textSecondary;
    }
  }

  //--------------------------------------------------------------------------
  String _getSeverityText() {
    switch (allergen.allergenicityIndex) {
      case 1:
        return 'Nizak alergijski potencijal';
      case 2:
        return 'Umeren alergijski potencijal';
      case 3:
        return 'Visok alergijski potencijal';
      default:
        return 'Nepoznat alergijski potencijal';
    }
  }
}
