import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../pedigree/presentation/providers/pedigree_providers.dart';

class BackupMigrationScreen extends ConsumerStatefulWidget {
  const BackupMigrationScreen({super.key});

  @override
  ConsumerState<BackupMigrationScreen> createState() => _BackupMigrationScreenState();
}

class _BackupMigrationScreenState extends ConsumerState<BackupMigrationScreen> {
  String _dbSize = 'Calculating...';
  bool _isVacuuming = false;

  @override
  void initState() {
    super.initState();
    _calculateDbSize();
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
        final bytes = await dbFile.length();
        final size = _formatBytes(bytes);
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

            Text(
              'Export & Import',
              style: TextStyle(
                fontSize: isTablet ? 20.0 : 18.0,
                fontWeight: FontWeight.bold,
                color: AppTheme.secondaryColor,
              ),
            ),
            SizedBox(height: padding),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _exportDatabase(context),
                icon: const Icon(Icons.upload_file),
                label: const Text('Export Database File (.sqlite)'),
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
                label: const Text('Restore Database from File'),
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
    try {
      final dir = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dir.path, 'zooped.sqlite'));
      
      if (!await dbFile.exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No database found to export.')),
          );
        }
        return;
      }

      final backupName = 'zooped_backup_${DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first}.sqlite';
      
      // We copy it to a temporary file with a nice name to share
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(p.join(tempDir.path, backupName));
      await dbFile.copy(tempFile.path);

      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: 'ZooPed Database Backup',
        subject: 'ZooPed Backup',
      );
      
      _calculateDbSize();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting: $e')),
        );
      }
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
            'WARNING: This will completely replace your current database with the backup file. '
            'Any data added since the backup will be lost!\n\n'
            'Please manually copy the backup .sqlite file into the app\'s documents directory '
            'and name it "zooped.sqlite" to restore, then restart the app. '
            '(In-app restore requires file picker integration which is beyond this scope).'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('I Understand'),
            ),
          ],
        ),
      );

      if (confirmed == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please manually replace the file and restart.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing: $e')),
        );
      }
    }
  }
}
