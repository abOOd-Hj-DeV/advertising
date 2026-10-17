@TestOn('vm')
library;

import 'dart:io';
import 'dart:typed_data';
import 'package:advertising/data/media_io.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'native media storage writes durable bytes and restricts path traversal',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'marketplace-media-test-',
      );
      addTearDown(() => dir.delete(recursive: true));
      final disk = FileMediaStorage(dir);
      final bytes = Uint8List.fromList([137, 80, 78, 71, 1, 2, 3, 4]);
      await disk.put('media-123', bytes);
      expect(await FileMediaStorage(dir).get('media-123'), bytes);
      expect(await disk.keys(), ['media-123']);
      expect(() => disk.file('../escape'), throwsArgumentError);
      expect(
        dir.listSync().whereType<File>().any((f) => f.path.endsWith('.tmp')),
        isFalse,
      );
      await disk.remove('media-123');
      expect(await disk.get('media-123'), isNull);
    },
  );
}
