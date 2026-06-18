import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _changelog = [
    (
      version: '1.4.0',
      date: '2026-06-17',
      entries: [
        'Unified FileStorageService eliminating orphaned high-res images memory leaks',
        'Refactored Heat Tracker to use autoDispose providers, solving stream bloat',
        'Implemented global robust DatabaseException error boundaries',
        'Parallel pedigree and gallery loading to eliminate UI thread blocking',
        'Enforced strict tap-only UX on complex detail tabs to prevent lag',
      ],
    ),
    (
      version: '1.3.0',
      date: '2026-06-17',
      entries: [
        'Optimized dog lookup: flat get (1 query) vs full pedigree (2 queries)',
        'Added Matchmaker with COI prediction using concurrent pedigree loading',
        'Added SQL search indexes for instant call-name/microchip lookups',
        'Replaced heat tracker Dart filter with SQL push-down for 1000+ dog kennels',
        'Removed 12 redundant use-case files; repositories injected directly',
        'Eliminated analyzer warnings across the entire codebase',
        'Added keep-alive caching for instant back-navigation from detail screens',
        'Fixed database migration crash on transactions(dog_id) index creation',
        'Added core library desugaring for Android SDK 33+ compatibility',
        'Settings screen reordered: Kennel Profile, Backup, Appearance, About',
      ],
    ),
    (
      version: '1.2.0',
      date: '2026-06-17',
      entries: [
        'Added Litters & Offspring tab to Dog Details',
        'Added dynamic Dashboard Sorting and Sex Filtering',
        'Introduced Appearance Settings: Dark/Light modes & 6 custom accent colors',
        'Completely overhauled Pedigree Certificate PDF into an A4 Landscape format with generation tree and inline images',
        'Achieved zero-warning compiler architecture and fixed context leaks',
      ],
    ),
    (
      version: '1.1.1',
      date: '2026-06-17',
      entries: [
        'Added specific Phone, WhatsApp, and Email fields to Kennel Profile',
        'Fixed dashboard not updating instantly after deleting a dog',
        'Added SQLite VACUUM to properly compress database on size refresh',
        'Migrated database schema to v6',
      ],
    ),
    (
      version: '1.1.0',
      date: '2026-06-17',
      entries: [
        'Edit existing dog profiles via /dog/:id/edit route',
        'List all registered litters with sire/dam names and puppy counts',
        'Add photos to dog profiles; displayed on detail screen',
        'CSV Import validation skips duplicates by registered name and microchip',
        'Replaced N+1 recursive queries with batched ancestor loading',
      ],
    ),
    (
      version: '1.0.1',
      date: '2026-06-17',
      entries: [
        'Added Great Grandparents to pedigree tree (5-generation display)',
        'Fixed pedigree tree connection wires rendering',
        'Fixed duplicate dog database insertion error',
        'Patched memory leak in pedigree canvas',
        'Resolved duplicate search suggestion entries',
        'Updated about screen logo and layout',
      ],
    ),
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
                  'Version 1.3.0',
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
