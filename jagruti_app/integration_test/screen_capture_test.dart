import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:jagruti_app/main.dart' as app;
import 'package:jagruti_app/db/database_helper.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture screenshots for all major screens', (tester) async {
    await _seedDummyMembers();
    app.main();

    await _waitFor(tester, find.text('Enter 4-Digit Password'));
    final shouldConvertSurface = Platform.isAndroid || Platform.isIOS;

    if (shouldConvertSurface) {
      // Needed to avoid blank screenshots on mobile surface renderers.
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
    }
    await _capture(binding, tester, '01_login');

    final pinFields = find.byType(TextField);
    await tester.enterText(pinFields.at(0), '1');
    await tester.enterText(pinFields.at(1), '0');
    await tester.enterText(pinFields.at(2), '0');
    await tester.enterText(pinFields.at(3), '8');
    if (find.text('Unlock').evaluate().isNotEmpty) {
      await tester.tap(find.text('Unlock'), warnIfMissed: false);
    }

    await _waitFor(tester, find.text('Dashboard'));
    await _capture(binding, tester, '02_dashboard');

    await _openDrawer(tester);
    await _capture(binding, tester, '03_drawer');

    await tester.tap(find.text('Members').last);
    await tester.pumpAndSettle();
    await _waitFor(tester, find.text('Members'));
    await _capture(binding, tester, '04_members_list');

    await tester.tap(find.byIcon(Icons.grid_view_outlined).first);
    await tester.pumpAndSettle();
    await _capture(binding, tester, '05_members_grid');

    final firstGridCard = find.descendant(
      of: find.byType(GridView),
      matching: find.byType(InkWell),
    ).first;
    await tester.tap(firstGridCard);
    await tester.pumpAndSettle();
    await _waitFor(tester, find.text('Member Profile'));
    await _capture(binding, tester, '06_member_profile');

    await tester.pageBack();
    await tester.pumpAndSettle();

    await _openDrawer(tester);
    await tester.tap(find.text('Reports').last);
    await tester.pumpAndSettle();
    await _waitFor(tester, find.text('Demographics'));
    await _capture(binding, tester, '07_reports');

    await _openDrawer(tester);
    await tester.tap(find.text('User Manual').last);
    await tester.pumpAndSettle();
    await _waitFor(tester, find.text('User Manual'));
    await _capture(binding, tester, '08_user_manual');

    await tester.tap(find.byIcon(Icons.notifications_none_outlined));
    await tester.pumpAndSettle();
    await _waitFor(tester, find.text('Notifications'));
    await _capture(binding, tester, '09_notifications');
  }, timeout: const Timeout(Duration(minutes: 10)));
}

Future<void> _seedDummyMembers() async {
  final db = await DatabaseHelper().database;
  final members = await db.query('members');
  if (members.isEmpty) return;

  final tableInfo = await db.rawQuery('PRAGMA table_info(members)');
  final existingColumns = tableInfo
      .map((row) => (row['name'] ?? '').toString())
      .where((name) => name.isNotEmpty)
      .toSet();
  if (existingColumns.isEmpty) return;

  const firstNames = [
    'Aarav',
    'Isha',
    'Vivaan',
    'Diya',
    'Kian',
    'Meera',
    'Rohan',
    'Nisha',
    'Kabir',
    'Anaya',
  ];
  const middleNames = ['K', 'M', 'R', 'S', 'T', 'P'];
  const lastNames = [
    'Patel',
    'Shah',
    'Mehta',
    'Joshi',
    'Trivedi',
    'Desai',
    'Vora',
    'Parikh',
  ];
  const gotras = ['Kashyap', 'Bharadwaj', 'Vashishtha', 'Gautam', 'Atri'];
  const cities = ['Ahmedabad', 'Surat', 'Rajkot', 'Vadodara', 'Bhavnagar'];
  const states = ['Gujarat', 'Maharashtra', 'Rajasthan'];
  const occupations = ['Teacher', 'Engineer', 'Doctor', 'Business', 'Designer'];
  const educations = ['B.Com', 'B.Tech', 'M.Sc', 'MBA', 'B.A'];
  const villages = ['Navsari', 'Patan', 'Dholka', 'Limbdi', 'Anjar'];

  final batch = db.batch();
  for (var i = 0; i < members.length; i++) {
    final source = Map<String, dynamic>.from(members[i]);
    final idx = i % firstNames.length;
    final memberId = (source['member_id'] ?? '').toString();

    final updated = <String, dynamic>{
      ...source,
      'title': i.isEven ? 'Mr.' : 'Mrs.',
      'first_name': firstNames[idx],
      'middle_name': middleNames[i % middleNames.length],
      'last_name': lastNames[i % lastNames.length],
      'gotra': gotras[i % gotras.length],
      'city': cities[i % cities.length],
      'state': states[i % states.length],
      'mobile': '900000${(1000 + i).toString().padLeft(4, '0')}',
      'email': 'member${i + 1}@example.com',
      'occupation': occupations[i % occupations.length],
      'education': educations[i % educations.length],
      'origin_village': villages[i % villages.length],
      'gender': i.isEven ? 'Male' : 'Female',
      'marital_status': i.isEven ? 'Married' : 'Single',
      'address': 'House ${i + 10}, Sample Society',
      'country': 'India',
      'zip_code': '3800${(i % 9) + 1}',
      'date_of_birth': '199${i % 10}-0${(i % 9) + 1}-1${i % 9}',
      'date_of_marriage': '201${i % 10}-0${(i % 9) + 1}-2${i % 8}',
      'photo_url': '',
    };

    final filtered = <String, dynamic>{};
    updated.forEach((key, value) {
      if (existingColumns.contains(key)) {
        filtered[key] = value;
      }
    });

    if (filtered.isEmpty) {
      continue;
    }

    if (memberId.isNotEmpty && existingColumns.contains('member_id')) {
      batch.update('members', filtered, where: 'member_id = ?', whereArgs: [memberId]);
    } else if (source.containsKey('id') && existingColumns.contains('id')) {
      batch.update('members', filtered, where: 'id = ?', whereArgs: [source['id']]);
    }
  }

  await batch.commit(noResult: true);
}

Future<void> _capture(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  await tester.pumpAndSettle();
  final bytes = await binding.takeScreenshot(name);

  final docsDir = await getApplicationDocumentsDirectory();
  final deviceDir = Directory(p.join(docsDir.path, 'screenshots'));
  if (!await deviceDir.exists()) {
    await deviceDir.create(recursive: true);
  }
  final deviceFile = File(p.join(deviceDir.path, '$name.png'));
  await deviceFile.writeAsBytes(bytes, flush: true);

  if (Platform.isAndroid) {
    try {
      final mirrorFile = File('/sdcard/$name.png');
      await mirrorFile.writeAsBytes(bytes, flush: true);
    } catch (_) {
      // Best effort mirror; local project copy is the canonical output.
    }
  }
}

Future<void> _openDrawer(WidgetTester tester) async {
  final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold).first);
  scaffoldState.openDrawer();
  await tester.pumpAndSettle();
}

Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  throw TestFailure('Timeout waiting for finder: $finder');
}
