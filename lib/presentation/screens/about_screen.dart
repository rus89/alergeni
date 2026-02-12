import 'package:alergeni/core/helpers/allergen_type_helper.dart';
import 'package:alergeni/core/helpers/severity_helper.dart';
import 'package:alergeni/core/theme/app_theme.dart';
import 'package:alergeni/data/models/allergen.dart';
import 'package:alergeni/presentation/viewmodels/home_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//--------------------------------------------------------------------------
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

//--------------------------------------------------------------------------
class _AboutScreenState extends State<AboutScreen> {
  Future<List<Allergen>>? _allergensFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _allergensFuture = context.read<HomeViewModel>().fetchAllergens();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final allergens = _allergensFuture;
    return Scaffold(
      appBar: AppBar(
        title: const Text('O aplikaciji'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: allergens == null
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(context, allergens),
    );
  }

  //--------------------------------------------------------------------------
  Widget _buildBody(BuildContext context, Future<List<Allergen>> allergens) {
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
                const Icon(Icons.eco, size: 80, color: AppTheme.primaryGreen),
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
    Future<List<Allergen>> allergens,
  ) {
    return FutureBuilder<List<Allergen>>(
      future: allergens,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Greška pri učitavanju alergena: ${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        }

        final allergens = snapshot.data ?? [];

        if (allergens.isEmpty) {
          return const Center(child: Text('Nema dostupnih alergena'));
        }

        // Sort by type, then by allergenicity index (low to high)
        allergens.sort((a, b) {
          final typeCompare = a.type.compareTo(b.type);
          if (typeCompare != 0) return typeCompare;
          return a.allergenicityIndex.compareTo(b.allergenicityIndex);
        });

        // Group by type
        final Map<int, List<Allergen>> groupedAllergens = {};
        for (var allergen in allergens) {
          groupedAllergens.putIfAbsent(allergen.type, () => []).add(allergen);
        }

        return Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Ime (Lat)')),
                DataColumn(label: Text('Ime (Sr)')),
                DataColumn(label: Text('Jačina alergena')),
              ],
              rows: [
                // Build rows for each type group
                for (var typeId in groupedAllergens.keys.toList()..sort()) ...[
                  // Section header for allergen type
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
                              AllergenTypeHelper.getLocalizedNameForType(
                                typeId,
                              ),
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
                  // Allergen rows for this type
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
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  SeverityHelper.allergenicityColorForConcentration(
                                    allergenicityIndex:
                                        allergen.allergenicityIndex,
                                    concentration: 100,
                                  ).withAlpha(50),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              SeverityHelper.allergenicityLabel(
                                allergen.allergenicityIndex,
                              ),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color:
                                        SeverityHelper.allergenicityColorForConcentration(
                                          allergenicityIndex:
                                              allergen.allergenicityIndex,
                                          concentration: 100,
                                        ),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
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
