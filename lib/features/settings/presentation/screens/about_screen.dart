import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = 'Loading...';

  List<({String version, String date, List<String> entries})>? _changelog;
  bool _changelogError = false;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
    _fetchChangelog();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = 'Version ${info.version}+${info.buildNumber}';
      });
    }
  }

  Future<void> _fetchChangelog() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/niiabe/zooped-flowos/releases'),
        headers: const {'Accept': 'application/vnd.github+json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<({String version, String date, List<String> entries})> fetched = [];

        for (final release in data) {
          final tagName = (release['tag_name'] as String?)?.trim() ?? '';
          if (tagName.isEmpty) continue;

          final rawDate = release['published_at'] as String? ?? '';
          final dateStr = rawDate.split('T').first;

          final body = (release['body'] as String?)?.trim() ?? '';
          final lines = body.split('\n');
          final entries = <String>[];
          
          for (var line in lines) {
            line = line.trim();
            if (line.startsWith('- ')) {
              // Strip bullet and asterisks (bold)
              line = line.substring(2).replaceAll('**', '').trim();
              if (line.isNotEmpty) entries.add(line);
            }
          }

          if (entries.isNotEmpty) {
            fetched.add((
              version: tagName.replaceAll('v', ''),
              date: dateStr,
              entries: entries,
            ));
          }
        }

        if (mounted) {
          setState(() {
            _changelog = fetched;
            _changelogError = false;
          });
        }
      } else {
        throw Exception('Failed to load');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _changelogError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.padding(context);
    final isTablet = Responsive.isTablet(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isTablet ? 600 : double.infinity),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(padding * 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/ZooPed_about.png',
                  height: isTablet ? 200.0 : 160.0,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Text(
                    'ZooPed',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: padding),
                Text(
                  _version,
                  style: TextStyle(
                    fontSize: isTablet ? 14.0 : 12.0,
                    color: Colors.grey.shade500,
                  ),
                ),
                SizedBox(height: padding * 3),
                const Divider(),
                SizedBox(height: padding),
                _buildInfoRow(
                  icon: Icons.person,
                  label: 'Developer',
                  value: 'NiiAbe',
                  isTablet: isTablet,
                ),
                SizedBox(height: padding),
                _buildInfoRow(
                  icon: Icons.language,
                  label: 'Website',
                  value: 'niiabe.github.io',
                  isTablet: isTablet,
                  onTap: () => _launchUrl('https://niiabe.github.io'),
                ),
                SizedBox(height: padding),
                _buildInfoRow(
                  icon: Icons.code,
                  label: 'Repository',
                  value: 'github.com/niiabe/zooped-flowos',
                  isTablet: isTablet,
                  onTap: () =>
                      _launchUrl('https://github.com/niiabe/zooped-flowos'),
                ),
                const Divider(),
                SizedBox(height: padding * 2),
                _buildChangelogSection(padding, isTablet),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChangelogSection(double padding, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history, size: 20, color: AppTheme.primaryColor),
            SizedBox(width: isTablet ? 12 : 8),
            Text(
              'Changelog',
              style: TextStyle(
                fontSize: isTablet ? 20.0 : 18.0,
                fontWeight: FontWeight.bold,
                color: AppTheme.secondaryColor,
              ),
            ),
          ],
        ),
        SizedBox(height: padding),
        if (_changelogError)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Unable to load changelog.\nPlease check your internet connection.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else if (_changelog == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_changelog!.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('No release history available.', style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          ..._changelog!.map((release) => _buildReleaseEntry(release, padding, isTablet)),
      ],
    );
  }

  Widget _buildReleaseEntry(
      ({String version, String date, List<String> entries}) release,
      double padding,
      bool isTablet) {
    return Card(
      margin: EdgeInsets.only(bottom: padding),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'v${release.version}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  release.date,
                  style: TextStyle(
                    fontSize: isTablet ? 13.0 : 12.0,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            SizedBox(height: padding * 0.75),
            ...release.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '\u2022 ',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry,
                          style: TextStyle(
                            fontSize: isTablet ? 14.0 : 13.0,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isTablet,
    VoidCallback? onTap,
  }) {
    final row = Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        SizedBox(width: isTablet ? 16 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isTablet ? 13.0 : 12.0,
                  color: Colors.grey.shade500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: isTablet ? 16.0 : 15.0,
                  color: onTap != null ? AppTheme.primaryColor : Colors.black87,
                  fontWeight: FontWeight.w500,
                  decoration: onTap != null
                      ? TextDecoration.underline
                      : TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
        if (onTap != null)
          const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: row,
        ),
      );
    }
    return row;
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
