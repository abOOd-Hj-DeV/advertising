import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/demo_store.dart';
import 'api/api_store.dart';
import 'api/backend_store.dart';
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
        'تعذّر الوصول للتخزين. التغييرات مؤقتة فقط.';
  }
  try {
    await MediaRepository.initialize();
  } catch (_) {
    startupError = 'تعذّر الوصول لصور الجهاز. الاستيراد معطّل.';
    MediaRepository.instance.importEnabled = false;
  }
  // With --dart-define=API_BASE=... every data path goes through the backend;
  // otherwise the app stays on the offline demo store.
  final api = await ApiStore.boot();
  final DemoStore store = api == null
      ? DemoStore(preferences: preferences, startupError: startupError)
      : BackendStore(api, preferences: preferences);
  if (store.storageError == null && store.persistenceAvailable) {
    await MediaRepository.instance.removeUnused(store.mediaReferences);
  }
  runApp(MarketplaceApp(store: store));
}
