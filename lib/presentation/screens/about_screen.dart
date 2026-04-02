import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:udahni/core/helpers/allergen_type_helper.dart';
import 'package:udahni/core/helpers/severity_helper.dart';
import 'package:udahni/core/theme/app_theme.dart';
import 'package:udahni/data/models/allergen.dart';
import 'package:udahni/presentation/viewmodels/home_view_model.dart';
import 'package:udahni/presentation/widgets/error_state.dart';

//--------------------------------------------------------------------------
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

//--------------------------------------------------------------------------
class _AboutScreenState extends State<AboutScreen> {
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    final allergens = viewModel.allergens;

    return Scaffold(
      appBar: AppBar(
        title: const Text('O aplikaciji'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: allergens == null
          ? viewModel.error != null
              ? ErrorState(
                  error: viewModel.error!,
                  onRetry: viewModel.fetchAllergens,
                )
              : const Center(child: CircularProgressIndicator())
          : _buildBody(context, allergens),
    );
  }

  //--------------------------------------------------------------------------
  Widget _buildBody(BuildContext context, List<Allergen> allergens) {
    final mutedTextColor = Theme.of(context).colorScheme.onSurfaceVariant;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                // logo
                Image.asset('assets/icon/icon.png', width: 80, height: 80),
                const SizedBox(height: 8.0),
                Text(
                  'Udahni',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // version
                const SizedBox(height: 4.0),
                Text(
                  'Verzija 1.0.0',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: mutedTextColor),
                ),

                const SizedBox(height: 16.0),
                const Divider(height: 32.0),

                // data source
                _buildInfoCard(
                  context: context,
                  title: 'Izvor podataka',
                  content:
                      'Otvoreni podaci Republike Srbije - Pollen Data API (https://data.gov.rs/)',
                  icon: Icons.data_usage,
                ),

                // update frequency
                const SizedBox(height: 16.0),
                _buildInfoCard(
                  context: context,
                  title: 'Učestalost ažuriranja',
                  content:
                      'Podaci o koncentracijama polena se ažuriraju nedeljno tokom sezone praćenja polena (februar - oktobar).',
                  icon: Icons.update,
                ),

                // statistics
                const SizedBox(height: 16.0),
                _buildInfoCard(
                  context: context,
                  title: 'Statistika korišćenja',
                  content:
                      '29 mernih stanica \n'
                      '26 praćenih alergena',
                  icon: Icons.bar_chart,
                ),

                const SizedBox(height: 24.0),
                const Divider(height: 32.0),

                // Allergens table
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Praćeni alergeni',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),
                _buildAllergensTable(context, allergens),

                const SizedBox(height: 24.0),
                const Divider(height: 32.0),

                // developer info
                Text(
                  'Aplikaciju je razvio samostalni programer kao lični projekat sa ciljem pružanja korisnih informacija osobama koje pate od alergija na polen.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: mutedTextColor),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //--------------------------------------------------------------------------
  Widget _buildAllergensTable(
    BuildContext context,
    List<Allergen> allergens,
  ) {
    if (allergens.isEmpty) {
      return const Center(child: Text('Nema dostupnih alergena'));
    }

    final groupedAllergens = _groupAllergensByType(allergens);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 700;
        if (isCompact) {
          return _buildCompactAllergensList(context, groupedAllergens);
        }

        return _buildWideAllergensTable(
          context,
          groupedAllergens,
          constraints.maxWidth,
        );
      },
    );
  }

  //--------------------------------------------------------------------------
  Map<int, List<Allergen>> _groupAllergensByType(List<Allergen> allergens) {
    final sortedAllergens = allergens.toList()
      ..sort((a, b) {
        final typeCompare = a.type.compareTo(b.type);
        if (typeCompare != 0) return typeCompare;
        return a.allergenicityIndex.compareTo(b.allergenicityIndex);
      });

    final groupedAllergens = <int, List<Allergen>>{};
    for (final allergen in sortedAllergens) {
      groupedAllergens.putIfAbsent(allergen.type, () => []).add(allergen);
    }
    return groupedAllergens;
  }

  //--------------------------------------------------------------------------
  Widget _buildWideAllergensTable(
    BuildContext context,
    Map<int, List<Allergen>> groupedAllergens,
    double maxWidth,
  ) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: maxWidth - 32),
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Ime (Lat)')),
              DataColumn(label: Text('Ime (Sr)')),
              DataColumn(label: Text('Jačina alergena')),
            ],
            rows: [
              for (final typeId in groupedAllergens.keys.toList()..sort()) ...[
                DataRow(
                  color: WidgetStateProperty.all(
                    AllergenTypeHelper.getColorForType(typeId).withAlpha(30),
                  ),
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          AllergenTypeHelper.getIconForType(typeId),
                          const SizedBox(width: 8),
                          Text(
                            AllergenTypeHelper.getLocalizedNameForType(typeId),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${groupedAllergens[typeId]!.length})',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const DataCell(SizedBox()),
                    const DataCell(SizedBox()),
                  ],
                ),
                ...groupedAllergens[typeId]!.map(
                  (allergen) => DataRow(
                    cells: [
                      DataCell(
                        Text(
                          allergen.name,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontStyle: FontStyle.italic),
                        ),
                      ),
                      DataCell(
                        Text(
                          allergen.localizedName,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      DataCell(_buildAllergenicityChip(context, allergen)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  //--------------------------------------------------------------------------
  Widget _buildCompactAllergensList(
    BuildContext context,
    Map<int, List<Allergen>> groupedAllergens,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final typeId in groupedAllergens.keys.toList()..sort()) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AllergenTypeHelper.getIconForType(typeId),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AllergenTypeHelper.getLocalizedNameForType(typeId),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        '${groupedAllergens[typeId]!.length}',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...groupedAllergens[typeId]!.map(
                    (allergen) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    allergen.localizedName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    allergen.name,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          fontStyle: FontStyle.italic,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildAllergenicityChip(context, allergen),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  //--------------------------------------------------------------------------
  Widget _buildAllergenicityChip(BuildContext context, Allergen allergen) {
    final color = SeverityHelper.allergenicityColorForConcentration(
      allergenicityIndex: allergen.allergenicityIndex,
      concentration: 100,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(50),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        SeverityHelper.allergenicityLabel(allergen.allergenicityIndex),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  //--------------------------------------------------------------------------
  Widget _buildInfoCard({
    required BuildContext context,
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryGreen, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
