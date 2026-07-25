import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/services/backup_service.dart';
import '../../../pedigree/presentation/providers/pedigree_providers.dart';

class BackupMigrationScreen extends ConsumerStatefulWidget {
  const BackupMigrationScreen({super.key});

  @override
  ConsumerState<BackupMigrationScreen> createState() => _BackupMigrationScreenState();
}

class _BackupMigrationScreenState extends ConsumerState<BackupMigrationScreen> {
  String _dbSize = 'Calculating...';
  bool _isVacuuming = false;
  bool _includeMedia = true;
  String _lastBackupDate = 'Never';
  String _lastRestoreDate = 'Never';

  @override
  void initState() {
    super.initState();
    _calculateDbSize();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    final lastBackup = await BackupService.getLastBackupDate();
    final lastRestore = await BackupService.getLastRestoreDate();
    if (mounted) {
      setState(() {
        _lastBackupDate = lastBackup != null
            ? DateFormat('yyyy-MM-dd HH:mm').format(lastBackup)
            : 'Never';
        _lastRestoreDate = lastRestore != null
            ? DateFormat('yyyy-MM-dd HH:mm').format(lastRestore)
            : 'Never';
      });
    }
  }

  Future<void> _calculateDbSize() async {
    try {
      if (mounted) {
        setState(() {
          _dbSize = 'Calculating...';
          _isVacuuming = true;
        });
      }
      // Run VACUUM to shrink and optimize the DB before calculating its size
      try {
        final db = ref.read(databaseProvider);
        await db.customStatement('VACUUM');
      } catch (_) {
        // ignore errors if VACUUM fails (e.g. if DB is locked)
      }

      if (mounted) setState(() => _isVacuuming = false);

      final dir = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dir.path, 'zooped.sqlite'));
      if (await dbFile.exists()) {
        int totalBytes = await dbFile.length();
        // Include WAL and SHM files in the size calculation
        final walFile = File('${dbFile.path}-wal');
        final shmFile = File('${dbFile.path}-shm');
        if (await walFile.exists()) totalBytes += await walFile.length();
        if (await shmFile.exists()) totalBytes += await shmFile.length();
        // Include media if enabled
        if (_includeMedia) {
          final imagesDir = Directory(p.join(dir.path, 'zooped_images'));
          if (await imagesDir.exists()) {
            final files = imagesDir.listSync(recursive: true);
            for (final file in files) {
              if (file is File) totalBytes += await file.length();
            }
          }
        }
        final size = _formatBytes(totalBytes);
        if (mounted) setState(() => _dbSize = size);
      } else {
        if (mounted) setState(() => _dbSize = 'No database found');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dbSize = 'Unknown';
          _isVacuuming = false;
        });
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.padding(context);
    final isTablet = Responsive.isTablet(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Migration'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.storage, color: AppTheme.primaryColor, size: 28),
                  ),
                  SizedBox(width: padding),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Database Size',
                          style: TextStyle(
                            fontSize: isTablet ? 16.0 : 14.0,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.secondaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              _dbSize,
                              style: TextStyle(
                                fontSize: isTablet ? 24.0 : 20.0,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            if (_isVacuuming) ...[
                              const SizedBox(width: 12),
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: padding * 2),

            Container(
              width: double.infinity,
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: AppTheme.secondaryColor.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.history, color: AppTheme.secondaryColor, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Backup History',
                        style: TextStyle(
                          fontSize: isTablet ? 16.0 : 14.0,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: padding),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Last Backup:', style: TextStyle(color: Colors.grey.shade600)),
                      Text(_lastBackupDate, style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Last Restored:', style: TextStyle(color: Colors.grey.shade600)),
                      Text(_lastRestoreDate, style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: padding * 2),

            Text(
              'Export & Import',
              style: TextStyle(
                fontSize: isTablet ? 20.0 : 18.0,
                fontWeight: FontWeight.bold,
                color: AppTheme.secondaryColor,
              ),
            ),
            SizedBox(height: padding),

            SwitchListTile(
              title: const Text('Backup Media (Images and Videos)'),
              subtitle: const Text('Turn off to backup only the database (smaller file size)'),
              value: _includeMedia,
              onChanged: (val) {
                setState(() => _includeMedia = val);
              },
              contentPadding: EdgeInsets.zero,
              activeColor: AppTheme.primaryColor,
            ),
            SizedBox(height: padding),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _exportDatabase(context),
                icon: const Icon(Icons.upload_file),
                label: Text('Export Backup (.zip) ${_includeMedia ? "(Database + Media)" : "(Database Only)"}'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: isTablet ? 16.0 : 12.0),
                ),
              ),
            ),
            SizedBox(height: padding),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _importDatabase(context),
                icon: const Icon(Icons.download),
                label: const Text('Restore Full Backup from Zip'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: isTablet ? 16.0 : 12.0),
                ),
              ),
            ),
            SizedBox(height: padding),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _calculateDbSize,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh database size'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportDatabase(BuildContext context) async {
    setState(() => _isVacuuming = true);
    final success = await BackupService.createAndShareBackup(includeMedia: _includeMedia);
    setState(() => _isVacuuming = false);
    
    if (success) {
      _loadMetadata();
    }
    
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create backup.')),
      );
    }
  }

  Future<void> _importDatabase(BuildContext context) async {
    try {
      if (!context.mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Restore from Backup?'),
          content: const Text(
            'WARNING: This will completely replace your current database and images with the backup file. '
            'Any data added since the backup will be lost!\n\n'
            'Do you want to proceed and select a backup .zip file?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Select Backup'),
            ),
          ],
        ),
      );

      if (confirmed == true && context.mounted) {
        setState(() => _isVacuuming = true);
        final success = await BackupService.restoreBackup();
        setState(() => _isVacuuming = false);
        
        if (context.mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Restore successful! Please completely restart the app for changes to take effect.')),
            );
            _calculateDbSize();
            _loadMetadata();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Restore failed or was canceled.')),
            );
          }
        }
      }
    } catch (e) {
      setState(() => _isVacuuming = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing: $e')),
        );
      }
    }
  }
}
