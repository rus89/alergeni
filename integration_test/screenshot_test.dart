// ABOUTME: Integration test that captures Play Store screenshots by navigating real app state.
// ABOUTME: Must be run via `flutter drive` on a real emulator — not `flutter test`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udahni/presentation/widgets/location_selector_card.dart';
import 'package:udahni/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Ensure a frame is rasterized into FlutterImageView before each takeScreenshot.
  // Without this, takeScreenshot blocks its RPC reply waiting for a frame that
  // never arrives.
  Future<void> settleForScreenshot(WidgetTester tester) async {
    await tester.pump();
    await Future.delayed(const Duration(milliseconds: 500));
    await tester.pump();
  }

  testWidgets('capture Play Store screenshots', (tester) async {
    // 1. Pre-seed SharedPreferences (clear first for clean state on repeated runs)
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setBool('onboarding_complete', true);
    await prefs.setStringList('visited_screens', ['home', 'map', 'allergens']);
    await prefs.setInt('selected_location_id', 1);
    await prefs.setString('personal_allergen_ids', '[9,10,3]');

    // 2. Launch the real app with real providers
    app.main();

    // 3. Wait for location fetch + pollen data fetch to complete.
    //    LocationSelectorCard appears only after both are done.
    //    pumpAndSettle() is unsafe here — loading spinner keeps the tree busy.
    var found = false;
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(seconds: 2));
      if (find.byType(LocationSelectorCard).evaluate().isNotEmpty) {
        found = true;
        break;
      }
    }
    if (!found) {
      fail(
        'LocationSelectorCard not found after 60 seconds — is the API reachable?',
      );
    }

    // 4. Switch the Flutter surface to image-capture mode. Must be called once,
    //    after the UI is stable, before any takeScreenshot.
    await binding.convertFlutterSurfaceToImage();

    // 5. Screenshot 1: Home screen
    await settleForScreenshot(tester);
    await binding.takeScreenshot('01_home');

    // 6. Navigate to Map tab
    await tester.tap(find.byIcon(Icons.map_outlined));

    // 7. Tab animation only — pumpAndSettle() unsafe here: flutter_map setState on each tile load
    await tester.pump(const Duration(milliseconds: 300));

    // 8. Wait for map tiles to load. Sized for the largest viewport (pixel_tablet):
    //    smaller devices finish sooner but this runs once per device, so the idle
    //    time is acceptable.
    await Future.delayed(const Duration(seconds: 15));

    // 9. Screenshot 2: Map
    await settleForScreenshot(tester);
    await binding.takeScreenshot('02_map');

    // 10. Open profile/settings screen via gear icon
    await tester.tap(find.byIcon(Icons.settings_outlined));

    // 11. Wait for profile screen (safe to use pumpAndSettle — no ongoing animations)
    await tester.pumpAndSettle();

    // 12. Screenshot 3: Profile/settings
    await settleForScreenshot(tester);
    await binding.takeScreenshot('03_profile');

    // 13. Close the fullscreenDialog. tester.pageBack() can't be used here —
    //     it only finds a Back tooltip or CupertinoNavigationBarBackButton,
    //     whereas fullscreenDialog injects a Material CloseButton (Icons.close)
    //     with a localized tooltip.
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // 14. Navigate to Home tab
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();

    // 15. Scroll so LocationSelectorCard goes off-screen and WeeklySummaryCard
    //     sits at the top. Without this the shot is visually identical to 01_home.
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();

    // 16. Screenshot 4: Home scrolled to weekly summary
    await settleForScreenshot(tester);
    await binding.takeScreenshot('04_weekly');
  });
}
