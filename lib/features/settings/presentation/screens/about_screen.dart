import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = 'Version ${info.version}+${info.buildNumber}';
      });
    }
  }

  static const _changelog = [
    (
      version: '1.9.2+18',
      date: '2026-07-16',
      entries: [
        'Bug Fix: Fixed an issue where backup files exported with absolute paths causing them to appear empty during restore',
        'Added Full Google Drive Backup & Restore functionality from the Settings screen',
        'Added option to include or exclude media (images/videos) from the backup file',
        'Revamped Litters & Offspring UI: Puppies are now neatly grouped into expandable folders under their respective litters',
      ],
    ),
    (
      version: '1.8.0+15',
      date: '2026-07-15',
      entries: [
        'In-App Update Checker: check for new versions from Settings > App Updates, then download and install the signed APK directly in the app',
        'Automatic launch prompt when a newer GitHub release is available, with release notes and Update / Later / Skip options',
        'Skip this version support so the launch prompt won\'t nag you about a release you dismissed',
        'Automated GitHub Actions release pipeline that builds, signs, verifies, and publishes the APK on every version tag',
      ],
    ),
    (
      version: '1.7.0+14',
      date: '2026-06-21',
      entries: [
        'Architectural Scaling & Optimization Update',
        'Memory Optimization: Converted FutureProvider database streams to autoDispose to instantly release memory resources',
        'Isolate Offloading: Migrated the heavy A4 Pedigree PDF Generator and compression logic entirely off the UI thread onto a background compute() isolate',
        'Data Security Integration: Hardened the SQLite persistence layer with comprehensive input boundary sanitization',
        'N+1 Database Query Fix: Re-engineered the lineage tree traversal engine away from an O(N) recursive loop to a batched, Depth-based O(Depth) query',
        'File Storage Permanence: Migrated all dog and kennel images automatically into a persistent, un-deletable app sandbox',
        'UX Search Debouncing: Installed an asynchronous backend Future.delayed cancellation layer on the Dashboard Search Bar',
      ],
    ),
    (
      version: '1.6.0+13',
      date: '2026-06-21',
      entries: [
        'Massive upgrade to PDF Export: 3-generation pedigree certificate with custom borders, colors, signatures, and breeder logos',
        'Whelped date removed from certificate',
      ],
    ),
    (
      version: '1.5.0+12',
      date: '2026-06-21',
      entries: [
        'Predictive Breed Input: the Breed field now auto-completes breeds from your Kennel Profile as you type',
        'Dynamic Versioning: the About screen reads the version number dynamically from the build configuration',
        'Social Pedigree Sharing: the Social share button now shares a rasterized image of the PDF certificate instead of a raw canvas screenshot',
        'Breed information is now visible throughout the app (Dashboard, Dog Details, Certificate, Analytics)',
        'Fixed transparent background on the generated social share image',
        'Cleaned up the PDF Certificate watermark to only show the ZooPed logo',
      ],
    ),
    (
      version: '1.4.1+11',
      date: '2026-06-20',
      entries: [
        'Restored the Heat Tracker screen which was incorrectly displaying the Matchmaker tab',
        'Litters list now auto-refreshes instantly upon returning from the Add Litter screen',
        'Enabled global live input validation (e.g., Microchip Number warns instantly while typing)',
        'Stripped 10+ older historical changelog data points to reduce app bundle weight',
      ],
    ),
    (
      version: '1.4.0+10',
      date: '2026-06-20',
      entries: [
        'Prevented infinite circular pedigree loops by filtering descendants out of sire/dam selection',
        'Auto-repairs corrupted circular lineage when opening the Edit Dog screen',
        'Added EXACT_ALARM Android permissions to fix crashing when adding health records',
        'Health records now guarantee saving even if the device blocks reminder notifications',
      ],
    ),
    (
      version: '1.4.0+9',
      date: '2026-06-20',
      entries: [
        'Fixed critical bug where adding a missing parent via pedigree canvas deleted the other parent',
        'Dogs added directly from pedigree canvas now properly default to "Not Owned" sale status',
      ],
    ),
    (
      version: '1.4.0+8',
      date: '2026-06-20',
      entries: [
        'Added "Not Owned" option to sale status dropdowns to categorize non-owned parent dogs in pedigrees',
        'Pedigree PDF Watermark: added a large ZooPed logo and paw prints as a background watermark on exported certificates',
        'Dog Profile Banner Image: the dog\'s profile picture now displays as a circular avatar in the Dog Detail top banner',
        'Filtered "Not Owned" dogs from the main kennel dashboard list and search results',
        'Enforced strict numeric input formatting on Microchip, Phone, and Financial fields',
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
