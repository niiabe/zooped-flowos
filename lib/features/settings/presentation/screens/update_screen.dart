import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/services/update_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';

class UpdateScreen extends StatefulWidget {
  const UpdateScreen({super.key});

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

enum _ViewState { idle, checking, upToDate, available, downloading, error }

class _UpdateScreenState extends State<UpdateScreen> {
  final UpdateService _service = UpdateService();

  _ViewState _state = _ViewState.idle;
  String _currentVersion = '...';
  UpdateInfo? _update;
  UpdateProgress? _progress;
  String? _error;
  StreamSubscription<UpdateProgress>? _sub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _currentVersion = info.version);
    }
    _checkForUpdate();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _service.dispose();
    super.dispose();
  }

  Future<void> _checkForUpdate() async {
    setState(() {
      _state = _ViewState.checking;
      _error = null;
    });
    try {
      final update = await _service.checkForUpdate();
      if (!mounted) return;
      setState(() {
        if (update == null) {
          _state = _ViewState.upToDate;
        } else {
          _update = update;
          _state = _ViewState.available;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _ViewState.error;
        _error = e.toString();
      });
    }
  }

  void _startDownload() {
    final update = _update;
    if (update == null) return;
    setState(() {
      _state = _ViewState.downloading;
      _progress = const UpdateProgress(status: UpdateDownloadStatus.downloading);
    });
    _sub?.cancel();
    _sub = _service.downloadAndInstall(update).listen((progress) {
      if (!mounted) return;
      setState(() => _progress = progress);
      if (progress.status == UpdateDownloadStatus.failed) {
        setState(() {
          _state = _ViewState.error;
          _error = progress.error ?? 'Download failed.';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.padding(context);
    final isTablet = Responsive.isTablet(context);

    return Scaffold(
      appBar: AppBar(title: const Text('App Updates')),
      body: Center(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: isTablet ? 600 : double.infinity),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(padding * 1.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(padding, isTablet),
                SizedBox(height: padding * 1.5),
                _buildBody(padding, isTablet),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double padding, bool isTablet) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.system_update,
                  color: AppTheme.primaryColor, size: isTablet ? 32 : 28),
            ),
            SizedBox(width: padding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Installed Version',
                    style: TextStyle(
                      fontSize: isTablet ? 14.0 : 13.0,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'v$_currentVersion',
                    style: TextStyle(
                      fontSize: isTablet ? 20.0 : 18.0,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(double padding, bool isTablet) {
    switch (_state) {
      case _ViewState.idle:
      case _ViewState.checking:
        return _buildChecking(padding);
      case _ViewState.upToDate:
        return _buildUpToDate(padding, isTablet);
      case _ViewState.available:
        return _buildAvailable(padding, isTablet);
      case _ViewState.downloading:
        return _buildDownloading(padding, isTablet);
      case _ViewState.error:
        return _buildError(padding, isTablet);
    }
  }

  Widget _buildChecking(double padding) {
    return Column(
      children: [
        const CircularProgressIndicator(),
        SizedBox(height: padding),
        Text(
          'Checking for updates...',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildUpToDate(double padding, bool isTablet) {
    return Column(
      children: [
        Icon(Icons.check_circle, color: Colors.green.shade600, size: 64),
        SizedBox(height: padding),
        Text(
          "You're up to date",
          style: TextStyle(
            fontSize: isTablet ? 20.0 : 18.0,
            fontWeight: FontWeight.bold,
            color: AppTheme.secondaryColor,
          ),
        ),
        SizedBox(height: padding * 0.5),
        Text(
          'ZooPed is running the latest available version.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        SizedBox(height: padding * 1.5),
        OutlinedButton.icon(
          onPressed: _checkForUpdate,
          icon: const Icon(Icons.refresh),
          label: const Text('Check Again'),
        ),
      ],
    );
  }

  Widget _buildAvailable(double padding, bool isTablet) {
    final update = _update!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 0,
          color: AppTheme.primaryColor.withValues(alpha: 0.06),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.new_releases,
                        color: AppTheme.primaryColor, size: isTablet ? 28 : 24),
                    SizedBox(width: padding * 0.5),
                    Expanded(
                      child: Text(
                        'Update available: v${update.version}',
                        style: TextStyle(
                          fontSize: isTablet ? 18.0 : 16.0,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (update.fileSize > 0) ...[
                  SizedBox(height: padding * 0.5),
                  Text(
                    'Download size: ${_formatBytes(update.fileSize)}',
                    style: TextStyle(
                      fontSize: isTablet ? 13.0 : 12.0,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
                if (update.releaseNotes.isNotEmpty) ...[
                  SizedBox(height: padding),
                  Text(
                    "What's new",
                    style: TextStyle(
                      fontSize: isTablet ? 15.0 : 14.0,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                  SizedBox(height: padding * 0.5),
                  Text(
                    update.releaseNotes,
                    style: TextStyle(
                      fontSize: isTablet ? 14.0 : 13.0,
                      height: 1.4,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        SizedBox(height: padding * 1.5),
        FilledButton.icon(
          onPressed: _startDownload,
          icon: const Icon(Icons.download),
          label: Text('Download & Install v${update.version}'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        SizedBox(height: padding * 0.5),
        TextButton(
          onPressed: () => _skipVersion(update),
          child: Text(
            'Skip this version',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }

  Future<void> _skipVersion(UpdateInfo update) async {
    await _service.skipVersion(update.version);
    if (!mounted) return;
    setState(() => _state = _ViewState.upToDate);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Version v${update.version} will be skipped.')),
    );
  }

  Widget _buildDownloading(double padding, bool isTablet) {
    final progress = _progress;
    final isInstalling =
        progress?.status == UpdateDownloadStatus.installing ||
            progress?.status == UpdateDownloadStatus.completed;
    final percent = progress?.percent ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isInstalling ? 'Starting installer...' : 'Downloading update...',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isTablet ? 16.0 : 15.0,
            fontWeight: FontWeight.w600,
            color: AppTheme.secondaryColor,
          ),
        ),
        SizedBox(height: padding),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: isInstalling
                ? null
                : (percent > 0 ? percent : null),
            minHeight: 10,
          ),
        ),
        SizedBox(height: padding * 0.5),
        if (!isInstalling && progress != null && progress.total > 0)
          Text(
            '${_formatBytes(progress.received)} / ${_formatBytes(progress.total)}  '
            '(${(percent * 100).toStringAsFixed(0)}%)',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        if (isInstalling) ...[
          SizedBox(height: padding),
          Text(
            'Please confirm the installation prompt from Android to finish updating.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ],
    );
  }

  Widget _buildError(double padding, bool isTablet) {
    return Column(
      children: [
        Icon(Icons.error_outline, color: Colors.red.shade600, size: 64),
        SizedBox(height: padding),
        Text(
          'Something went wrong',
          style: TextStyle(
            fontSize: isTablet ? 20.0 : 18.0,
            fontWeight: FontWeight.bold,
            color: AppTheme.secondaryColor,
          ),
        ),
        SizedBox(height: padding * 0.5),
        Text(
          _error ?? 'Unable to check for updates.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        SizedBox(height: padding * 1.5),
        OutlinedButton.icon(
          onPressed: _checkForUpdate,
          icon: const Icon(Icons.refresh),
          label: const Text('Try Again'),
        ),
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    return '${size.toStringAsFixed(size >= 10 || unit == 0 ? 0 : 1)} ${units[unit]}';
  }
}
