import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:archive/archive_io.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackupService {
  static const _lastBackupDateKey = 'last_backup_date';
  static const _lastRestoreDateKey = 'last_restore_date';

  static Future<DateTime?> getLastBackupDate() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_lastBackupDateKey);
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  static Future<DateTime?> getLastRestoreDate() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_lastRestoreDateKey);
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

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

      final tempDir = await getApplicationDocumentsDirectory();
      // Clean up any previously created backups to avoid accumulation
      try {
        final existing = tempDir
            .listSync()
            .whereType<File>()
            .where((f) => p.basename(f.path).startsWith('zooped_backup_'))
            .toList();
        for (final f in existing) {
          await f.delete();
        }
      } catch (_) {
        // Ignore cleanup errors
      }

      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final zipPath = p.join(tempDir.path, 'zooped_backup_$dateStr.zip');

      final encoder = ZipFileEncoder();
      encoder.create(zipPath);

      // Add database along with its WAL/Shm companions so no recent data is lost
      await encoder.addFile(dbFile, 'zooped.sqlite');
      final walFile = File('${dbFile.path}-wal');
      final shmFile = File('${dbFile.path}-shm');
      if (await walFile.exists()) await encoder.addFile(walFile, 'zooped.sqlite-wal');
      if (await shmFile.exists()) await encoder.addFile(shmFile, 'zooped.sqlite-shm');

      // Add images if they exist and includeMedia is true
      if (includeMedia && await imagesDir.exists()) {
        final files = imagesDir.listSync(recursive: true);
        for (final file in files) {
          if (file is File) {
            // This will create a path like 'zooped_images/filename.jpg'
            final relativePath = p.relative(file.path, from: appDir.path);
            // On Windows p.relative uses '\', so ensure zip uses '/'
            final zipEntryName = relativePath.replaceAll('\\', '/');
            await encoder.addFile(file, zipEntryName);
          }
        }
      }

      await encoder.close();

      final xFile = XFile(zipPath, mimeType: 'application/zip');
      await Share.shareXFiles(
        [xFile],
        text: 'ZooPed Backup $dateStr',
        subject: 'ZooPed Database Backup',
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastBackupDateKey, DateTime.now().millisecondsSinceEpoch);
      
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
          final baseName = p.basename(filename);
          if (baseName == 'zooped.sqlite' ||
              baseName == 'zooped.sqlite-wal' ||
              baseName == 'zooped.sqlite-shm') {
            final target = p.join(appDir.path, baseName);
            await File(target).writeAsBytes(data, flush: true);
            if (baseName == 'zooped.sqlite') hasDb = true;
          } else if (filename.startsWith('zooped_images/')) {
            final extractPath = p.join(appDir.path, filename);
            await File(extractPath).create(recursive: true);
            await File(extractPath).writeAsBytes(data, flush: true);
          }
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastRestoreDateKey, DateTime.now().millisecondsSinceEpoch);

      return hasDb;
    } catch (e) {
      debugPrint('BackupService: Error restoring backup: $e');
      return false;
    }
  }
}
