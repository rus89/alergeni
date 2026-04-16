// ABOUTME: Integration test driver — receives screenshot bytes from device and saves as PNGs.
// ABOUTME: Runs on the host machine via `flutter drive`, not on the device.

import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
  onScreenshot:
      (String name, List<int> bytes, [Map<String, Object?>? args]) async {
        final deviceName =
            Platform.environment['SCREENSHOT_DEVICE_NAME'] ?? 'phone';
        final file = File('assets/screenshots/raw/$deviceName/$name.png');
        file.parent.createSync(recursive: true);
        file.writeAsBytesSync(bytes);
        return true;
      },
);
