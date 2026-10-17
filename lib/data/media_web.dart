import 'dart:typed_data';
import 'package:idb_shim/idb_browser.dart';
import 'media.dart';

Future<MediaStorage> createMediaStorage() async {
  final db = await idbFactoryBrowser.open(
    'anzeigen-local-media',
    version: 1,
    onUpgradeNeeded: (event) {
      event.database.createObjectStore('images');
    },
  );
  return BrowserMediaStorage(db);
}

class BrowserMediaStorage implements MediaStorage {
  BrowserMediaStorage(this.db);
  final Database db;
  @override
  Future<void> put(String id, Uint8List bytes) async {
    final tx = db.transaction('images', idbModeReadWrite);
    await tx.objectStore('images').put(bytes, id);
    await tx.completed;
  }

  @override
  Future<Uint8List?> get(String id) async {
    final tx = db.transaction('images', idbModeReadOnly);
    final value = await tx.objectStore('images').getObject(id);
    await tx.completed;
    if (value is Uint8List) return value;
    if (value is List) return Uint8List.fromList(value.cast<int>());
    return null;
  }

  @override
  Future<List<String>> keys() async {
    final tx = db.transaction('images', idbModeReadOnly);
    final keys = await tx.objectStore('images').getAllKeys();
    await tx.completed;
    return keys.cast<String>();
  }

  @override
  Future<void> remove(String id) async {
    final tx = db.transaction('images', idbModeReadWrite);
    await tx.objectStore('images').delete(id);
    await tx.completed;
  }
}
