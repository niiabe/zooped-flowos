import 'dart:io';
import 'package:flutter/foundation.dart';

class FileStorageService {
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
