import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';

class PedigreeCardNode extends StatelessWidget {
  final String roleName;
  final bool isMale;
  final String? callName;
  final String? registeredName;
  final String? microchip;
  final String? registerType;
  final VoidCallback onTap;

  const PedigreeCardNode({
    super.key,
    required this.roleName,
    required this.isMale,
    required this.onTap,
    this.callName,
    this.registeredName,
    this.microchip,
    this.registerType,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEmptyPlaceholder = callName == null;
    final bool isMobile = Responsive.isMobile(context);
    final bool isTablet = Responsive.isTablet(context);

    // Responsive card dimensions
    final double cardWidth = isMobile ? 140.0 : (isTablet ? 160.0 : 180.0);
    final double cardHeight = isMobile ? 70.0 : (isTablet ? 78.0 : 86.0);
    final double padding = isMobile ? 6.0 : 8.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        height: cardHeight,
        padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 0.8),
        decoration: BoxDecoration(
          color: isEmptyPlaceholder ? Colors.transparent : Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isEmptyPlaceholder ? Colors.grey.shade400 : Colors.grey.shade200,
            width: isEmptyPlaceholder ? 1.5 : 1.0,
          ),
          boxShadow: isEmptyPlaceholder
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6.0,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: isEmptyPlaceholder 
            ? _buildEmptyState(context) 
            : _buildFilledState(context),
      ),
    );
  }

  Widget _buildFilledState(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Role Title and Gender Accent Line
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                roleName.toUpperCase(),
                style: TextStyle(
                  fontSize: isMobile ? 7.0 : 9.0,
                  fontWeight: FontWeight.bold,
                  color: isMale ? Colors.blue.shade700 : Colors.pink.shade700,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              isMale ? Icons.male : Icons.female,
              size: isMobile ? 10.0 : 12.0,
              color: isMale ? Colors.blue.shade400 : Colors.pink.shade400,
            ),
          ],
        ),
        // Core Identity Content Block
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              callName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isMobile ? 11.0 : 13.0,
                fontWeight: FontWeight.bold,
                color: AppTheme.secondaryColor,
              ),
            ),
            Text(
              registeredName ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isMobile ? 8.0 : 10.0,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        // Microchip Summary Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                microchip != null ? 'Chip: $microchip' : 'No Chip',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isMobile ? 7.0 : 9.0,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
            if (registerType != null)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 2.0 : 4.0,
                  vertical: 1.0,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2.0),
                ),
                child: Text(
                  registerType!,
                  style: TextStyle(
                    fontSize: isMobile ? 6.0 : 8.0,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryColor,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_circle_outline,
          size: isMobile ? 14.0 : 18.0,
          color: Colors.grey.shade500,
        ),
        const SizedBox(height: 4.0),
        Text(
          'Link $roleName',
          style: TextStyle(
            fontSize: isMobile ? 8.0 : 10.0,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
