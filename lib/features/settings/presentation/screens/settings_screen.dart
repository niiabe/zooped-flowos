import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTablet = Responsive.isTablet(context);
    final padding = Responsive.padding(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Application Settings',
              style: TextStyle(
                fontSize: isTablet ? 22.0 : 20.0,
                fontWeight: FontWeight.bold,
                color: AppTheme.secondaryColor,
              ),
            ),
            SizedBox(height: padding * 1.5),
            _buildSectionCard(
              context,
              icon: Icons.pets,
              title: 'Kennel Profile',
              subtitle: 'Manage your kennel name, breeder info, and logo',
              color: AppTheme.defaultPrimaryColor,
              onTap: () => context.push('/settings/kennel'),
            ),
            SizedBox(height: padding),
            _buildSectionCard(
              context,
              icon: Icons.backup,
              title: 'Backup & Migration',
              subtitle: 'Export or import your database, view storage usage',
              color: Colors.orange.shade700,
              onTap: () => context.push('/settings/backup'),
            ),
            SizedBox(height: padding),
            _buildSectionCard(
              context,
              icon: Icons.palette,
              title: 'Appearance',
              subtitle: 'Theme mode and accent colors',
              color: Colors.purple.shade600,
              onTap: () => context.push('/settings/appearance'),
            ),
            SizedBox(height: padding),
            _buildSectionCard(
              context,
              icon: Icons.info_outline,
              title: 'About ZooPed',
                subtitle: 'Version 1.4.0',
              color: Colors.blue.shade700,
              onTap: () => context.push('/about'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isTablet = Responsive.isTablet(context);
    final padding = Responsive.padding(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: isTablet ? 32 : 28),
              ),
              SizedBox(width: padding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isTablet ? 18.0 : 16.0,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: isTablet ? 14.0 : 13.0,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
