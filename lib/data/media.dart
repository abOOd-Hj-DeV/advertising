import 'dart:typed_data';
import 'dart:ui' as ui;
import 'media_memory.dart'
    if (dart.library.io) 'media_io.dart'
    if (dart.library.js_interop) 'media_web.dart'
    as platform;

abstract class MediaStorage {
  Future<void> put(String id, Uint8List bytes);
  Future<Uint8List?> get(String id);
  Future<List<String>> keys();
  Future<void> remove(String id);
}

class MediaRepository {
  MediaRepository(this.storage);
  static MediaRepository instance = MediaRepository(MemoryMediaStorage());
  static const maxFileBytes = 2 * 1024 * 1024;
  static const maxTotalBytes = 24 * 1024 * 1024;
  final MediaStorage storage;
  final Map<String, Future<Uint8List?>> _cache = {};
  Future<void> _mutations = Future.value();
  final Set<String> pending = {};
  String? cleanupWarning;
  bool importEnabled = true;
  static Future<void> initialize() async {
    instance = MediaRepository(await platform.createMediaStorage());
  }

  Future<Uint8List?> get(String key) =>
      _cache.putIfAbsent(key, () => storage.get(key));
  Future<T> _ordered<T>(Future<T> Function() operation) {
    final next = _mutations.then((_) => operation());
    _mutations = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  Future<String> importImage(String filename, Uint8List bytes) =>
      _ordered(() => _importImage(filename, bytes));
  Future<String> _importImage(String filename, Uint8List bytes) async {
    if (!importEnabled) {
      throw const FormatException(
        'Bildspeicher nicht verfügbar. Import deaktiviert.',
      );
    }
    final ext = filename.toLowerCase().split('.').last;
    final png =
        bytes.length > 8 &&
        bytes[0] == 137 &&
        bytes[1] == 80 &&
        bytes[2] == 78 &&
        bytes[3] == 71;
    final jpeg =
        bytes.length > 3 &&
        bytes[0] == 255 &&
        bytes[1] == 216 &&
        bytes[2] == 255;
    if (!['jpg', 'jpeg', 'png'].contains(ext) || (!png && !jpeg)) {
      throw const FormatException(
        'Nur echte JPEG- und PNG-Bilder werden unterstützt.',
      );
    }
    if (bytes.length > maxFileBytes) {
      throw const FormatException('Maximal 2 MB pro Bild.');
    }
    ui.Codec? codec;
    ui.Image? image;
    try {
      final (width, height) = imageDimensions(bytes);
      if (width < 1 ||
          height < 1 ||
          width > 4096 ||
          height > 4096 ||
          width * height > 12000000) {
        throw const FormatException(
          'Maximal 4096 Pixel je Seite und 12 Megapixel.',
        );
      }
      codec = await ui.instantiateImageCodec(bytes);
      image = (await codec.getNextFrame()).image;
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Das Bild ist beschädigt oder nicht lesbar.');
    } finally {
      image?.dispose();
      codec?.dispose();
    }
    var total = bytes.length;
    for (final key in await storage.keys()) {
      total += (await storage.get(key))?.length ?? 0;
    }
    if (total > maxTotalBytes) {
      throw const FormatException(
        'Der lokale Bildspeicher ist voll (24 MB). Entferne nicht benötigte Anzeigen/Entwürfe.',
      );
    }
    final id = 'media-${DateTime.now().microsecondsSinceEpoch}';
    await storage.put(id, bytes);
    _cache[id] = Future.value(bytes);
    return id;
  }

  Future<bool> removeUnused(Set<String> used) => _ordered(() async {
    try {
      for (final key in await storage.keys()) {
        if (!used.contains(key) && !pending.contains(key)) {
          await storage.remove(key);
          _cache.remove(key);
        }
      }
      cleanupWarning = null;
      return true;
    } catch (_) {
      cleanupWarning =
          'Nicht benötigte Bilder konnten nicht vollständig entfernt werden. Bitte Speicher prüfen und erneut versuchen.';
      return false;
    }
  });
}

// Web cannot read ImageDescriptor dimensions; check headers before decoding.
(int, int) imageDimensions(Uint8List bytes) {
  const bad = FormatException('Ungültiger JPEG-/PNG-Bildkopf.');
  if (bytes.length >= 24 &&
      bytes[0] == 137 &&
      bytes[1] == 80 &&
      bytes[2] == 78 &&
      bytes[3] == 71) {
    final data = ByteData.sublistView(bytes);
    if (bytes[12] != 73 ||
        bytes[13] != 72 ||
        bytes[14] != 68 ||
        bytes[15] != 82) {
      throw bad;
    }
    return (data.getUint32(16), data.getUint32(20));
  }
  if (bytes.length < 4 || bytes[0] != 255 || bytes[1] != 216) throw bad;
  var offset = 2;
  while (offset < bytes.length) {
    if (bytes[offset++] != 255) throw bad;
    while (offset < bytes.length && bytes[offset] == 255) {
      offset++;
    }
    if (offset >= bytes.length) throw bad;
    final marker = bytes[offset++];
    if (marker == 0xd9 || marker == 0xda) throw bad;
    if (marker == 0x01 || marker >= 0xd0 && marker <= 0xd8) continue;
    if (offset + 2 > bytes.length) throw bad;
    final length = bytes[offset] * 256 + bytes[offset + 1];
    if (length < 2 || offset + length > bytes.length) throw bad;
    if (const [
      0xc0,
      0xc1,
      0xc2,
      0xc3,
      0xc5,
      0xc6,
      0xc7,
      0xc9,
      0xca,
      0xcb,
      0xcd,
      0xce,
      0xcf,
    ].contains(marker)) {
      if (length < 8) throw bad;
      return (
        bytes[offset + 5] * 256 + bytes[offset + 6],
        bytes[offset + 3] * 256 + bytes[offset + 4],
      );
    }
    offset += length;
  }
  throw bad;
}

class MemoryMediaStorage implements MediaStorage {
  final Map<String, Uint8List> data = {};
  @override
  Future<void> put(String id, Uint8List bytes) async {
    data[id] = Uint8List.fromList(bytes);
  }

  @override
  Future<Uint8List?> get(String id) async => data[id];
  @override
  Future<List<String>> keys() async => data.keys.toList();
  @override
  Future<void> remove(String id) async {
    data.remove(id);
  }
}
