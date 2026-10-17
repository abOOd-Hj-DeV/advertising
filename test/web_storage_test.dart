import 'package:advertising/data/demo_store.dart';
import 'package:advertising/data/media.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'media_test.dart' show png;
import 'register_web_stub.dart'
    if (dart.library.js_interop) 'register_web.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Web IndexedDB preserves imported media across repository initialization',
    () async {
      await MediaRepository.initialize();
      final bytes = await png();
      final key = await MediaRepository.instance.importImage(
        'local.png',
        bytes,
      );
      await MediaRepository.initialize();
      expect(await MediaRepository.instance.get(key), bytes);
      await MediaRepository.instance.storage.remove(key);
    },
    skip: !kIsWeb,
  );
  test('Web snapshot write and reconstruction retain local models', () async {
    registerWebStorage();
    final p = await SharedPreferences.getInstance();
    final original = p.getString(DemoStore.storageKey);
    final s = DemoStore(preferences: p)..signIn();
    s.updateProfile('Browser Demo');
    s.saveDraft(ListingDraft(id: 'web-test', values: {'title': 'Im Browser'}));
    expect(await s.flush(), isTrue);
    final r = DemoStore(preferences: p);
    expect(r.name, 'Browser Demo');
    expect(r.drafts.any((d) => d.id == 'web-test'), isTrue);
    expect(r.signedIn, isFalse);
    if (original == null) {
      await p.remove(DemoStore.storageKey);
    } else {
      await p.setString(DemoStore.storageKey, original);
    }
    s.dispose();
    r.dispose();
  }, skip: !kIsWeb);
}
