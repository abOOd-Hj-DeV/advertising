import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'media.dart';

Future<MediaStorage> createMediaStorage() async {
  final root = await getApplicationSupportDirectory();
  final dir = await Directory(
    '${root.path}/marketplace-media',
  ).create(recursive: true);
  return FileMediaStorage(dir);
}

class FileMediaStorage implements MediaStorage {
  FileMediaStorage(this.directory);
  final Directory directory;
  File file(String id) {
    if (!RegExp(r'^media-[0-9]+$').hasMatch(id)) {
      throw ArgumentError('معرّف صورة غير صالح');
    }
    return File('${directory.path}/$id');
  }

  @override
  Future<void> put(String id, Uint8List bytes) async {
    final temp = File('${file(id).path}.tmp');
    await temp.writeAsBytes(bytes, flush: true);
    await temp.rename(file(id).path);
  }

  @override
  Future<Uint8List?> get(String id) async {
    final f = file(id);
    return await f.exists() ? f.readAsBytes() : null;
  }

  @override
  Future<List<String>> keys() async => directory
      .listSync()
      .whereType<File>()
      .map((f) => f.uri.pathSegments.last)
      .where((id) => RegExp(r'^media-[0-9]+$').hasMatch(id))
      .toList();
  @override
  Future<void> remove(String id) async {
    final f = file(id);
    if (await f.exists()) await f.delete();
  }
}
