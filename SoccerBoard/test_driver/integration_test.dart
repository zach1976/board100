import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Driver for the local UI runs — writes each takeScreenshot() to
/// SoccerBoard/screenshots/. Not part of any build or release.
Future<void> main() async {
  await integrationDriver(
    onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? _]) async {
      final file = File('screenshots/$name.png');
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);
      return true;
    },
  );
}
