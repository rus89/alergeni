import 'package:alergeni/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

//--------------------------------------------------------------------------
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('O aplikaciji'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _buildBody(context),
    );
  }

  //--------------------------------------------------------------------------
  Widget _buildBody(BuildContext context) {
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
                // Image.asset(
                //   'assets/images/app_logo.png',
                //   width: 100,
                //   height: 100,
                // ),
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
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
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
                  content: '29 mernih stanica \n 26 praćenih alergena',
                  icon: Icons.bar_chart,
                ),

                const SizedBox(height: 24.0),
                const Divider(height: 32.0),

                // developer info
                Text(
                  'Aplikaciju je razvio samostalni programer Milan Rusimov kao lični projekat sa ciljem pružanja korisnih informacija osobama koje pate od alergija na polen.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
