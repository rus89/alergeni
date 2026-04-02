// ABOUTME: Screen where users mark which allergens personally affect them.
// ABOUTME: Lists all 26 allergens grouped by type with toggles for selection.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:udahni/core/helpers/allergen_type_helper.dart';
import 'package:udahni/core/helpers/severity_helper.dart';
import 'package:udahni/data/models/allergen.dart';
import 'package:udahni/presentation/viewmodels/home_view_model.dart';
import 'package:udahni/presentation/viewmodels/personal_allergen_view_model.dart';

class PersonalAllergenScreen extends StatelessWidget {
  const PersonalAllergenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final allergens = context.read<HomeViewModel>().allergens ?? [];
    final personalVm = context.watch<PersonalAllergenViewModel>();

    final grouped = <int, List<Allergen>>{};
    for (final allergen in allergens) {
      grouped.putIfAbsent(allergen.type, () => []).add(allergen);
    }

    final sortedTypeIds = grouped.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moji alergeni'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: sortedTypeIds.length,
        itemBuilder: (context, sectionIndex) {
          final typeId = sortedTypeIds[sectionIndex];
          final typeAllergens = grouped[typeId]!
            ..sort((a, b) => a.localizedName.compareTo(b.localizedName));
          final typeName = AllergenTypeHelper.getLocalizedNameForType(typeId);
          final typeColor = AllergenTypeHelper.getColorForType(typeId);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    AllergenTypeHelper.getIconForType(typeId),
                    const SizedBox(width: 8),
                    Text(
                      typeName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: typeColor,
                      ),
                    ),
                  ],
                ),
              ),
              ...typeAllergens.map((allergen) {
                final isSelected = personalVm.isSelected(allergen.id);
                final allergenicityColor =
                    SeverityHelper.allergenicityBaseColor(
                      allergen.allergenicityIndex,
                    );
                final allergenicityLabel = SeverityHelper.allergenicityLabel(
                  allergen.allergenicityIndex,
                );

                return ListTile(
                  title: Text(allergen.localizedName),
                  subtitle: Text(
                    allergen.name,
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: allergenicityColor.withAlpha(51),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          allergenicityLabel,
                          style: TextStyle(
                            fontSize: 10,
                            color: allergenicityColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: isSelected,
                        onChanged: (_) =>
                            personalVm.toggleAllergen(allergen.id),
                        activeThumbColor: typeColor,
                      ),
                    ],
                  ),
                );
              }),
              if (sectionIndex < sortedTypeIds.length - 1)
                const Divider(height: 1),
            ],
          );
        },
      ),
    );
  }
}
