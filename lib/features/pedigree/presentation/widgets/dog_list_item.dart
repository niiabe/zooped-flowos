import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/dog.dart';

class DogListItem extends StatelessWidget {
  final Dog dog;
  final VoidCallback onTap;

  const DogListItem({
    super.key,
    required this.dog,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);
    final padding = Responsive.padding(context);

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: padding * 0.75,
        vertical: padding * 0.25,
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(
          horizontal: padding,
          vertical: padding * 0.5,
        ),
        leading: CircleAvatar(
          radius: isTablet ? 24.0 : 20.0,
          backgroundColor: dog.sex == 'Male' 
              ? Colors.blue.shade100 
              : Colors.pink.shade100,
          child: Icon(
            dog.sex == 'Male' ? Icons.male : Icons.female,
            color: dog.sex == 'Male' ? Colors.blue.shade700 : Colors.pink.shade700,
            size: isTablet ? 24.0 : 20.0,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dog.callName,
              style: TextStyle(
                fontSize: isTablet ? 18.0 : 16.0,
                fontWeight: FontWeight.bold,
                color: AppTheme.secondaryColor,
              ),
            ),
            Text(
              dog.registeredName,
              style: TextStyle(
                fontSize: isTablet ? 14.0 : 12.0,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Icon(
              dog.sex == 'Male' ? Icons.male : Icons.female,
              size: isTablet ? 14.0 : 12.0,
              color: dog.sex == 'Male' ? Colors.blue : Colors.pink,
            ),
            SizedBox(width: padding * 0.25),
            Text(
              dog.sex,
              style: TextStyle(
                fontSize: isTablet ? 12.0 : 10.0,
                color: dog.sex == 'Male' ? Colors.blue.shade700 : Colors.pink.shade700,
              ),
            ),
            if (dog.microchipNumber != null) ...[
              SizedBox(width: padding * 0.5),
              Text(
                'Chip: ${dog.microchipNumber}',
                style: TextStyle(
                  fontSize: isTablet ? 11.0 : 9.0,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          size: isTablet ? 28.0 : 24.0,
        ),
      ),
    );
  }
}
