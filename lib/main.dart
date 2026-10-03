import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/demo_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    for (final entry in const {
      'Nunito Sans': 'assets/fonts/OFL.txt',
      'Roboto': 'assets/fonts/Roboto-OFL.txt',
      'DejaVu Sans': 'assets/fonts/DejaVu-LICENSE.txt',
    }.entries) {
      yield LicenseEntryWithLineBreaks([
        entry.key,
      ], await rootBundle.loadString(entry.value));
    }
  });
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final preferences = await SharedPreferences.getInstance();
  runApp(MarketplaceApp(store: DemoStore(preferences: preferences)));
}
