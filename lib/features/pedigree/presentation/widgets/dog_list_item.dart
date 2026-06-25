import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
        leading: Hero(
          tag: 'dog_photo_${dog.id}',
          child: CircleAvatar(
            radius: isTablet ? 24.0 : 20.0,
            backgroundColor: dog.sex == 'Male' ? Colors.blue.shade100 : Colors.pink.shade100,
            backgroundImage: dog.photoPath != null ? ResizeImage(FileImage(File(dog.photoPath!)), width: 150) : null,
            child: dog.photoPath == null
                ? Icon(
                    dog.sex == 'Male' ? Icons.male : Icons.female,
                    color: dog.sex == 'Male' ? Colors.blue.shade700 : Colors.pink.shade700,
                    size: isTablet ? 24.0 : 20.0,
                  )
                : null,
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
            if (dog.breed != null && dog.breed!.isNotEmpty) ...[
              SizedBox(width: padding * 0.5),
              Text(
                '• ${dog.breed}',
                style: TextStyle(
                  fontSize: isTablet ? 11.0 : 9.0,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (dog.appraisalScore != null) ...[
              SizedBox(width: padding * 0.5),
              _buildMiniAppraisalBadge(dog.appraisalScore!, isTablet),
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

  Widget _buildMiniAppraisalBadge(double score, bool isTablet) {
    Color badgeColor;
    IconData icon;

    if (score >= 90) {
      badgeColor = Colors.amber.shade600;
      icon = Icons.emoji_events;
    } else if (score >= 80) {
      badgeColor = Colors.blueGrey.shade400;
      icon = Icons.workspace_premium;
    } else if (score >= 70) {
      badgeColor = Colors.brown.shade400;
      icon = Icons.military_tech;
    } else {
      badgeColor = Colors.grey.shade600;
      icon = Icons.verified;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isTablet ? 12.0 : 10.0, color: badgeColor),
          const SizedBox(width: 2.0),
          Text(
            score.toStringAsFixed(1),
            style: TextStyle(
              fontSize: isTablet ? 10.0 : 8.0,
              fontWeight: FontWeight.bold,
              color: badgeColor,
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}
