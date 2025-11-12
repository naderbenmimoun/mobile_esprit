import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:mime/mime.dart';

class StorageService {
  final _uuid = Uuid();

  /// Copie un fichier dans le dossier applicationDocuments/reclamations
  /// Retourne un String de type file://<path>
  Future<String> saveFileLocally(File file, {String? folder}) async {
    final dir = await getApplicationDocumentsDirectory();
    final destFolder = p.join(dir.path, folder ?? 'reclamations');
    final destDir = Directory(destFolder);
    if (!await destDir.exists()) {
      await destDir.create(recursive: true);
    }
    final ext = p.extension(file.path);
    final name = '${_uuid.v4()}$ext';
    final newPath = p.join(destFolder, name);
    final newFile = await file.copy(newPath);
    return Uri.file(newFile.path).toString();
  }

  /// Supprime un fichier local si le chemin est file://...
  Future<void> deleteLocalFile(String uriString) async {
    try {
      final uri = Uri.parse(uriString);
      if (uri.scheme == 'file') {
        final f = File.fromUri(uri);
        if (await f.exists()) {
          await f.delete();
        }
      }
    } catch (_) {
      // ignore
    }
  }

  /// Obtenir mime type
  String? mimeType(String path) {
    return lookupMimeType(path);
  }
}
