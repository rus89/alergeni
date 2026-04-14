// ABOUTME: Full-screen intro cards shown on first launch of the app.
// ABOUTME: Lets users skip or advance through 4 cards before entering the main app.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:udahni/core/services/onboarding_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _cards = [
    _CardData(
      icon: Icons.air,
      title: 'Dobrodošli',
      subtitle: 'Prati polene i alergene u Srbiji',
    ),
    _CardData(
      icon: Icons.home_outlined,
      title: 'Početna',
      subtitle:
          'Svaki dan dobijate snimak stanja polena za vašu lokaciju — '
          'birajte stanicu i pratite nivoe ozbiljnosti.',
    ),
    _CardData(
      icon: Icons.map_outlined,
      title: 'Mapa',
      subtitle:
          'Interaktivna karta Srbije prikazuje sve merne stanice. '
          'Tapnite marker da vidite detalje za tu stanicu.',
    ),
    _CardData(
      icon: Icons.favorite_outline,
      title: 'Moji alergeni',
      subtitle:
          'Označite alergene koji vas pogađaju i oni će biti istaknuti '
          'u vašim svakodnevnim izveštajima.',
    ),
  ];

  void _complete() async {
    final service = context.read<OnboardingService>();
    final navigator = Navigator.of(context);
    await service.markOnboardingComplete();
    if (!mounted) return;
    unawaited(navigator.pushReplacementNamed('/'));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _cards.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _cards.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) =>
                    _OnboardingCard(data: _cards[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _complete,
                    child: const Text('Preskoči'),
                  ),
                  const Spacer(),
                  _PageIndicator(
                    count: _cards.length,
                    current: _currentPage,
                  ),
                  const Spacer(),
                  isLast
                      ? FilledButton(
                          onPressed: _complete,
                          child: const Text('Počni'),
                        )
                      : FilledButton(
                          onPressed: () {
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: const Text('Dalje'),
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

//------------------------------------------------------------------------------
class _OnboardingCard extends StatelessWidget {
  final _CardData data;

  const _OnboardingCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(data.icon, size: 80, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 32),
          Text(
            data.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            data.subtitle,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

//------------------------------------------------------------------------------
class _PageIndicator extends StatelessWidget {
  final int count;
  final int current;

  const _PageIndicator({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        final active = index == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 16 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

//------------------------------------------------------------------------------
class _CardData {
  final IconData icon;
  final String title;
  final String subtitle;

  const _CardData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
