// ABOUTME: Unified profile and settings destination, accessible from the app bar.
// ABOUTME: Shows personal allergen selection and settings like replaying the onboarding intro.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:udahni/core/helpers/allergen_type_helper.dart';
import 'package:udahni/core/helpers/severity_helper.dart';
import 'package:udahni/core/services/onboarding_service.dart';
import 'package:udahni/data/models/allergen.dart';
import 'package:udahni/presentation/viewmodels/home_view_model.dart';
import 'package:udahni/presentation/viewmodels/personal_allergen_view_model.dart';
import 'package:udahni/presentation/widgets/hint_card.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final service = context.read<OnboardingService>();
      final visited = await service.hasVisitedScreen('allergens');
      if (!mounted) return;
      if (!visited) {
        setState(() => _showHint = true);
      }
    });
  }

  void _dismissHint() async {
    final service = context.read<OnboardingService>();
    await service.markScreenVisited('allergens');
    if (mounted) setState(() => _showHint = false);
  }

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
        title: const Text('Profil i podešavanja'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              const _SectionHeader(title: 'Moji alergeni'),
              if (sortedTypeIds.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Učitavanje alergena...'),
                )
              else
                ...sortedTypeIds.asMap().entries.map((entry) {
                  final sectionIndex = entry.key;
                  final typeId = entry.value;
                  final typeAllergens = grouped[typeId]!
                    ..sort(
                      (a, b) => a.localizedName.compareTo(b.localizedName),
                    );
                  final typeName =
                      AllergenTypeHelper.getLocalizedNameForType(typeId);
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
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
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
                        final allergenicityLabel =
                            SeverityHelper.allergenicityLabel(
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
                }),
              const Divider(height: 32),
              const _SectionHeader(title: 'Podešavanja'),
              ListTile(
                title: const Text('Ponovi uvod'),
                leading: const Icon(Icons.replay_outlined),
                onTap: () async {
                  final service = context.read<OnboardingService>();
                  final navigator = Navigator.of(context);
                  await service.resetOnboarding();
                  if (!mounted) return;
                  // ignore: unawaited_futures
                  navigator.pushReplacementNamed('/onboarding');
                },
              ),
            ],
          ),
          if (_showHint)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: HintCard(
                message:
                    'Označite alergene koji vas pogađaju — biće istaknuti '
                    'u svakodnevnim izveštajima.',
                onDismiss: _dismissHint,
              ),
            ),
        ],
      ),
    );
  }
}

//------------------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
