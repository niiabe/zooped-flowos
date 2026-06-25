import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class FileStorageService {
  /// Copies a temporary file to a permanent application storage location.
  /// Returns the new permanent path, or the original path if it fails.
  static Future<String> saveImagePermanently(String tempPath) async {
    try {
      final file = File(tempPath);
      if (!await file.exists()) return tempPath;

      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(appDir.path, 'zooped_images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final ext = p.extension(tempPath);
      final uniqueName = '${DateTime.now().millisecondsSinceEpoch}$ext';
      final newPath = p.join(imagesDir.path, uniqueName);

      final newFile = await file.copy(newPath);
      debugPrint('FileStorageService: Saved image permanently to $newPath');
      return newFile.path;
    } catch (e) {
      debugPrint('FileStorageService: Failed to save image permanently. Error: $e');
      return tempPath;
    }
  }

  /// Deletes a file from the device if it exists.
  /// Returns true if successfully deleted, false otherwise.
  static Future<bool> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        debugPrint('FileStorageService: Deleted $path');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('FileStorageService: Failed to delete file at $path. Error: $e');
      return false;
    }
  }
}
