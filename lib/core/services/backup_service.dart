import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:archive/archive_io.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

class BackupService {
  /// Compresses the database and optionally images into a zip file and shares it.
  static Future<bool> createAndShareBackup({bool includeMedia = true}) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(appDir.path, 'zooped.sqlite'));
      final imagesDir = Directory(p.join(appDir.path, 'zooped_images'));

      // Ensure we have a database to backup
      if (!await dbFile.exists()) {
        debugPrint('BackupService: Database file not found.');
        return false;
      }

      final tempDir = await getTemporaryDirectory();
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final zipPath = p.join(tempDir.path, 'zooped_backup_$dateStr.zip');

      final encoder = ZipFileEncoder();
      encoder.create(zipPath);

      // Add database
      encoder.addFile(dbFile);

      // Add images if they exist and includeMedia is true
      if (includeMedia && await imagesDir.exists()) {
        encoder.addDirectory(imagesDir);
      }

      encoder.close();

      final xFile = XFile(zipPath, mimeType: 'application/zip');
      await Share.shareXFiles(
        [xFile],
        text: 'ZooPed Backup $dateStr',
        subject: 'ZooPed Database Backup',
      );
      
      return true;
    } catch (e) {
      debugPrint('BackupService: Error creating backup: $e');
      return false;
    }
  }

  /// Prompts the user to pick a zip backup and restores it.
  /// NOTE: This replaces current data. App should be restarted or DB refreshed after this.
  static Future<bool> restoreBackup() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result == null || result.files.isEmpty) {
        return false; // User canceled
      }

      final zipPath = result.files.single.path;
      if (zipPath == null) return false;

      final bytes = await File(zipPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final appDir = await getApplicationDocumentsDirectory();
      final targetDbPath = p.join(appDir.path, 'zooped.sqlite');
      final targetImagesDir = p.join(appDir.path, 'zooped_images');

      // Create images dir if it doesn't exist
      final imgDir = Directory(targetImagesDir);
      if (!await imgDir.exists()) {
        await imgDir.create(recursive: true);
      }

      bool hasDb = false;

      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          if (filename == 'zooped.sqlite') {
            await File(targetDbPath).writeAsBytes(data, flush: true);
            hasDb = true;
          } else if (filename.startsWith('zooped_images/')) {
            final extractPath = p.join(appDir.path, filename);
            await File(extractPath).create(recursive: true);
            await File(extractPath).writeAsBytes(data, flush: true);
          }
        }
      }

      return hasDb;
    } catch (e) {
      debugPrint('BackupService: Error restoring backup: $e');
      return false;
    }
  }
}
