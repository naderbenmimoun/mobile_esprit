// utils/file_utils.dart
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

Future<File> getAssetAsFile(String assetPath) async {
  final byteData = await rootBundle.load(assetPath);
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/${assetPath.split('/').last}');
  await file.writeAsBytes(byteData.buffer.asUint8List());
  return file;
}
