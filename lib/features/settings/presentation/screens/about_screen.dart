import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _changelog = [
    (
      version: '1.0.0',
      date: '2026-06-14',
      entries: [
        'Dog identity management with full profile fields',
        'Interactive 3-generation pedigree tree with tap-to-navigate',
        '5-generation PDF certificate generation and sharing',
        'Litter tracking with 3-step wizard',
        'Puppy auto-create with parent references',
        'Custom kennel branding and logo upload',
        'CSV export and import from app documents',
        'Logo-driven theme (Green + Charcoal)',
        'Responsive design for phones and tablets',
        'About screen with developer info',
        'Offline-first SQLite storage via Drift',
      ],
    ),
  ];

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
                  'assets/images/appbarlogo.png',
                  height: isTablet ? 100.0 : 80.0,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Text(
                    'ZooPed',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: padding * 2),
                Text(
                  'ZooPed',
                  style: TextStyle(
                    fontSize: isTablet ? 28.0 : 24.0,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pedigree Documentation',
                  style: TextStyle(
                    fontSize: isTablet ? 16.0 : 14.0,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Version 1.0.0',
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
            Icon(Icons.history, size: 20, color: AppTheme.primaryColor),
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
        ..._changelog.map((release) => _buildReleaseEntry(release, padding, isTablet)),
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
                      Text(
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
