import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/demo_store.dart';
import 'api/api_store.dart';
import 'data/media.dart';

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
  SharedPreferences? preferences;
  String? startupError;
  try {
    preferences = await SharedPreferences.getInstance();
  } catch (_) {
    startupError =
        'Gerätespeicher nicht verfügbar. Änderungen bleiben nur vorübergehend.';
  }
  try {
    await MediaRepository.initialize();
  } catch (_) {
    startupError = 'Bildspeicher nicht verfügbar. Import ist deaktiviert.';
    MediaRepository.instance.importEnabled = false;
  }
  final store = DemoStore(preferences: preferences, startupError: startupError);
  if (store.storageError == null && store.persistenceAvailable) {
    await MediaRepository.instance.removeUnused(store.mediaReferences);
  }
  // When built with --dart-define=API_BASE=... the API layer boots and
  // restores the stored session token; screens fall back to DemoStore data.
  await ApiStore.boot();
  runApp(MarketplaceApp(store: store));
}
