import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:advertising/data/media.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Uint8List> png({int width = 2, int height = 2}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawPaint(ui.Paint()..color = const ui.Color(0xff297a30));
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final bytes = (await image.toByteData(
    format: ui.ImageByteFormat.png,
  ))!.buffer.asUint8List();
  image.dispose();
  picture.dispose();
  return bytes;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'JPEG header inspection and decoding work with bundled stock media',
    () async {
      final bytes = (await rootBundle.load(
        'assets/images/sofa.jpg',
      )).buffer.asUint8List();
      final (width, height) = imageDimensions(bytes);
      expect(width, greaterThan(0));
      expect(height, greaterThan(0));
      final repo = MediaRepository(MemoryMediaStorage());
      final id = await repo.importImage('sofa.jpg', bytes);
      expect(await repo.get(id), bytes);
    },
  );
  test(
    'concurrent imports cannot race past quota and cleanup protects in-progress editors',
    () async {
      final bytes = await png();
      final disk = MemoryMediaStorage();
      disk.data['media-1'] = Uint8List(
        MediaRepository.maxTotalBytes - bytes.length * 2 + 1,
      );
      final repo = MediaRepository(disk);
      final results = await Future.wait([
        for (var i = 0; i < 2; i++)
          repo
              .importImage('photo.png', bytes)
              .then<Object>((id) => id, onError: (Object e) => e),
      ]);
      expect(results.whereType<String>().length, 1);
      expect(results.whereType<FormatException>().length, 1);
      final id = results.whereType<String>().single;
      repo.pending.add(id);
      expect(await repo.removeUnused({}), isTrue);
      expect(await disk.get(id), bytes);
      repo.pending.remove(id);
      await repo.removeUnused({});
      expect(await disk.keys(), isEmpty);
    },
  );
  test(
    'validated imported bytes survive repository recreation and scoped cleanup',
    () async {
      final disk = MemoryMediaStorage();
      final repo = MediaRepository(disk);
      final bytes = await png();
      final a = await repo.importImage('Foto.PNG', bytes);
      final b = await repo.importImage('zweites.png', bytes);
      expect(a, isNot(b));
      expect(await MediaRepository(disk).get(a), bytes);
      await repo.removeUnused({b});
      expect(await disk.get(a), isNull);
      expect(await disk.get(b), bytes);
      expect(await repo.get(a), isNull);
    },
  );
  test(
    'bad extensions, spoofed content, broken images, huge bytes and dimensions are rejected',
    () async {
      final disk = MemoryMediaStorage();
      final repo = MediaRepository(disk);
      final valid = await png();
      await expectLater(
        repo.importImage('active.svg', valid),
        throwsFormatException,
      );
      await expectLater(
        repo.importImage('fake.png', Uint8List.fromList([1, 2, 3, 4])),
        throwsFormatException,
      );
      await expectLater(
        repo.importImage(
          'broken.jpg',
          Uint8List.fromList([255, 216, 255, 1, 2, 3, 4]),
        ),
        throwsFormatException,
      );
      final large = Uint8List(MediaRepository.maxFileBytes + 1);
      large.setAll(0, [137, 80, 78, 71, 13, 10, 26, 10]);
      await expectLater(
        repo.importImage('huge.png', large),
        throwsFormatException,
      );
      await expectLater(
        repo.importImage('wide.png', await png(width: 4097, height: 1)),
        throwsFormatException,
      );
      expect(await disk.keys(), isEmpty);
    },
  );
  test('quota rejects imports without replacing existing images', () async {
    final disk = MemoryMediaStorage();
    disk.data['media-1'] = Uint8List(MediaRepository.maxTotalBytes);
    final repo = MediaRepository(disk);
    await expectLater(
      repo.importImage('photo.png', await png()),
      throwsFormatException,
    );
    expect(await disk.keys(), ['media-1']);
  });
  test(
    'storage failures and disabled imports never return dangling image IDs',
    () async {
      final bytes = await png();
      final failing = MediaRepository(FailingMediaStorage());
      await expectLater(
        failing.importImage('photo.png', bytes),
        throwsStateError,
      );
      final disabled = MediaRepository(MemoryMediaStorage())
        ..importEnabled = false;
      await expectLater(
        disabled.importImage('photo.png', bytes),
        throwsFormatException,
      );
    },
  );
}

class FailingMediaStorage extends MemoryMediaStorage {
  @override
  Future<void> put(String id, Uint8List bytes) async {
    throw StateError('disk unavailable');
  }
}
