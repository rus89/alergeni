// ABOUTME: Widget tests for AboutScreen — verifies version label is sourced from PackageInfo.
// ABOUTME: Guards against hardcoded version strings drifting from pubspec.yaml.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:udahni/presentation/screens/about_screen.dart';
import 'package:udahni/presentation/viewmodels/home_view_model.dart';

import '../../helpers/fake_pollen_repository.dart';
import '../../helpers/test_data.dart';

Widget _buildTestApp(FakePollenRepository repo) {
  return ChangeNotifierProvider(
    create: (_) =>
        HomeViewModel(pollenRepository: repo)..fetchAllergens(),
    child: const MaterialApp(home: Scaffold(body: AboutScreen())),
  );
}

void main() {
  group('AboutScreen', () {
    testWidgets('renders version from PackageInfo', (tester) async {
      PackageInfo.setMockInitialValues(
        appName: 'Udahni',
        packageName: 'com.serbiaOpenData.udahni',
        version: '1.1.0',
        buildNumber: '3',
        buildSignature: '',
      );

      final repo = FakePollenRepository()
        ..allergensResult = [makeAllergen()];

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Verzija 1.1.0'), findsOneWidget);
    });
  });
}
