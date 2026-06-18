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

    // Dynamic width, minimum height
    final double cardWidth = isMobile ? 150.0 : (isTablet ? 170.0 : 200.0);
    final double minHeight = isMobile ? 80.0 : (isTablet ? 90.0 : 100.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        constraints: BoxConstraints(minHeight: minHeight),
        decoration: BoxDecoration(
          color: isEmptyPlaceholder ? Colors.transparent : Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isEmptyPlaceholder 
                ? Colors.grey.shade300 
                : (isMale ? Colors.blue.shade100 : Colors.pink.shade100),
            width: isEmptyPlaceholder ? 1.5 : 1.0,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
          boxShadow: isEmptyPlaceholder
              ? []
              : [
                  BoxShadow(
                    color: (isMale ? Colors.blue : Colors.pink).withValues(alpha: 0.05),
                    blurRadius: 10.0,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Gender color accent bar
                Container(
                  width: 4.0,
                  color: isEmptyPlaceholder 
                      ? Colors.transparent 
                      : (isMale ? Colors.blue.shade400 : Colors.pink.shade400),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                    child: isEmptyPlaceholder 
                        ? _buildEmptyState(context) 
                        : _buildFilledState(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilledState(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Role Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                roleName.toUpperCase(),
                style: TextStyle(
                  fontSize: isMobile ? 8.0 : 10.0,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.8,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              isMale ? Icons.male : Icons.female,
              size: isMobile ? 12.0 : 14.0,
              color: isMale ? Colors.blue.shade400 : Colors.pink.shade400,
            ),
          ],
        ),
        const SizedBox(height: 4.0),
        // Core Identity Content Block
        Text(
          callName!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: isMobile ? 12.0 : 14.0,
            fontWeight: FontWeight.bold,
            color: AppTheme.secondaryColor,
          ),
        ),
        if (registeredName != null && registeredName!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(
              registeredName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isMobile ? 9.0 : 11.0,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        const SizedBox(height: 6.0),
        // Microchip Summary Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                microchip != null && microchip!.isNotEmpty ? 'Chip: $microchip' : 'No Chip',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isMobile ? 9.0 : 10.0,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
            if (registerType != null && registerType!.isNotEmpty) ...[
              const SizedBox(width: 4.0),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 4.0 : 6.0,
                  vertical: 2.0,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  registerType!,
                  style: TextStyle(
                    fontSize: isMobile ? 8.0 : 9.0,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ]
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.add_circle_outline,
          size: isMobile ? 18.0 : 24.0,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 6.0),
        Text(
          'Link $roleName',
          style: TextStyle(
            fontSize: isMobile ? 10.0 : 12.0,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
