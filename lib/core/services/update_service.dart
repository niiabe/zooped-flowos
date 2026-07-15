import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateInfo {
  const UpdateInfo({
    required this.version,
    required this.tagName,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.assetName,
    required this.fileSize,
    required this.publishedAt,
  });

  final String version;
  final String tagName;
  final String releaseNotes;
  final String downloadUrl;
  final String assetName;
  final int fileSize;
  final DateTime? publishedAt;
}

enum UpdateDownloadStatus { downloading, installing, completed, failed }

class UpdateProgress {
  const UpdateProgress({
    required this.status,
    this.received = 0,
    this.total = 0,
    this.error,
  });

  final UpdateDownloadStatus status;
  final int received;
  final int total;
  final String? error;

  double get percent => total > 0 ? (received / total).clamp(0.0, 1.0) : 0.0;
}

class UpdateService {
  UpdateService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _owner = 'niiabe';
  static const String _repo = 'zooped-flowos';
  static const String _latestReleaseUrl =
      'https://api.github.com/repos/$_owner/$_repo/releases/latest';

  static const String _skippedVersionKey = 'update_skipped_version';

  /// Checks GitHub for the latest release. Returns [UpdateInfo] if a newer
  /// version than the currently installed one is available, otherwise null.
  ///
  /// When [respectSkip] is true, a version the user chose to skip is treated
  /// as if no update were available (used for the silent launch check).
  Future<UpdateInfo?> checkForUpdate({bool respectSkip = false}) async {
    final response = await _client.get(
      Uri.parse(_latestReleaseUrl),
      headers: const {'Accept': 'application/vnd.github+json'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to check for updates (HTTP ${response.statusCode}).',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final tagName = (data['tag_name'] as String?)?.trim() ?? '';
    if (tagName.isEmpty) return null;

    final latestVersion = _normalizeVersion(tagName);

    final assets = (data['assets'] as List<dynamic>? ?? []);
    final apkAsset = assets.cast<Map<String, dynamic>>().firstWhere(
          (a) => (a['name'] as String? ?? '').toLowerCase().endsWith('.apk'),
          orElse: () => <String, dynamic>{},
        );

    if (apkAsset.isEmpty) return null;

    final info = await PackageInfo.fromPlatform();
    final currentVersion = _normalizeVersion(info.version);

    if (_compareVersions(latestVersion, currentVersion) <= 0) {
      return null;
    }

    if (respectSkip && await isVersionSkipped(latestVersion)) {
      return null;
    }

    return UpdateInfo(
      version: latestVersion,
      tagName: tagName,
      releaseNotes: (data['body'] as String?)?.trim() ?? '',
      downloadUrl: apkAsset['browser_download_url'] as String,
      assetName: apkAsset['name'] as String,
      fileSize: (apkAsset['size'] as num?)?.toInt() ?? 0,
      publishedAt: DateTime.tryParse(data['published_at'] as String? ?? ''),
    );
  }

  /// Downloads the APK for [update] and launches the system installer.
  /// Emits progress events throughout the process.
  Stream<UpdateProgress> downloadAndInstall(UpdateInfo update) async* {
    IOSink? sink;
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${update.assetName}');
      if (await file.exists()) {
        await file.delete();
      }

      final request = http.Request('GET', Uri.parse(update.downloadUrl));
      final response = await _client.send(request);

      if (response.statusCode != 200) {
        yield UpdateProgress(
          status: UpdateDownloadStatus.failed,
          error: 'Download failed (HTTP ${response.statusCode}).',
        );
        return;
      }

      final total = response.contentLength ?? update.fileSize;
      var received = 0;
      sink = file.openWrite();

      yield UpdateProgress(
        status: UpdateDownloadStatus.downloading,
        received: 0,
        total: total,
      );

      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        yield UpdateProgress(
          status: UpdateDownloadStatus.downloading,
          received: received,
          total: total,
        );
      }

      await sink.flush();
      await sink.close();
      sink = null;

      yield UpdateProgress(
        status: UpdateDownloadStatus.installing,
        received: received,
        total: total,
      );

      final result = await OpenFilex.open(
        file.path,
        type: 'application/vnd.android.package-archive',
      );

      if (result.type == ResultType.done) {
        yield UpdateProgress(
          status: UpdateDownloadStatus.completed,
          received: received,
          total: total,
        );
      } else {
        yield UpdateProgress(
          status: UpdateDownloadStatus.failed,
          received: received,
          total: total,
          error: 'Could not open installer: ${result.message}',
        );
      }
    } catch (e, stack) {
      debugPrint('Update download failed: $e\n$stack');
      await sink?.close();
      yield UpdateProgress(
        status: UpdateDownloadStatus.failed,
        error: e.toString(),
      );
    }
  }

  /// Marks [version] so the silent launch check won't prompt for it again.
  Future<void> skipVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_skippedVersionKey, version);
  }

  /// Whether the user previously chose to skip [version].
  Future<bool> isVersionSkipped(String version) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_skippedVersionKey) == version;
  }

  void dispose() => _client.close();

  String _normalizeVersion(String raw) {
    var v = raw.trim();
    if (v.toLowerCase().startsWith('v')) v = v.substring(1);
    // Drop build metadata and pre-release suffixes for comparison purposes.
    v = v.split('+').first;
    v = v.split('-').first;
    return v;
  }

  /// Returns > 0 if [a] is newer than [b], 0 if equal, < 0 if older.
  int _compareVersions(String a, String b) {
    final pa = _versionParts(a);
    final pb = _versionParts(b);
    final length = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < length; i++) {
      final na = i < pa.length ? pa[i] : 0;
      final nb = i < pb.length ? pb[i] : 0;
      if (na != nb) return na.compareTo(nb);
    }
    return 0;
  }

  List<int> _versionParts(String version) => version
      .split('.')
      .map((p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
      .toList();
}
