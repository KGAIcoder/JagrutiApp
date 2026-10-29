import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver_extended.dart';
import 'package:path/path.dart' as p;

Future<void> main() async {
  final outputDir = Directory(p.join('screenshots', 'app_screens'));
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  await integrationDriver(
    onScreenshot: (String screenshotName, List<int> screenshotBytes, [Map<String, Object?>? args]) async {
      final file = File(p.join(outputDir.path, '$screenshotName.png'));
      await file.writeAsBytes(screenshotBytes, flush: true);
      return true;
    },
    responseDataCallback: (Map<String, dynamic>? data) async {
      if (data == null) {
        return;
      }
      final manifest = File(p.join(outputDir.path, 'manifest.json'));
      await manifest.writeAsString(const JsonEncoder.withIndent('  ').convert(data), flush: true);
    },
  );
}
