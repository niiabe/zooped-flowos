import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/pedigree_providers.dart';

final upcomingWhelpingsProvider = StreamProvider.autoDispose<List<Mating>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchUpcomingWhelpings();
});

class UpcomingWhelpingWidget extends ConsumerWidget {
  const UpcomingWhelpingWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final whelpingsAsync = ref.watch(upcomingWhelpingsProvider);

    return whelpingsAsync.when(
      data: (matings) {
        if (matings.isEmpty) return const SizedBox.shrink();

        return Container(
          height: 120,
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: matings.length,
            itemBuilder: (context, index) {
              final mating = matings[index];
              final expectedWhelpDate = mating.matingDate.add(const Duration(days: 63));
              final daysLeft = expectedWhelpDate.difference(DateTime.now()).inDays;
              
              return _buildWhelpingCard(context, ref, mating, expectedWhelpDate, daysLeft);
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildWhelpingCard(BuildContext context, WidgetRef ref, Mating mating, DateTime whelpDate, int daysLeft) {
    final damAsync = ref.watch(dogByIdProvider(mating.damId));
    
    return Card(
      margin: const EdgeInsets.only(right: 12.0),
      elevation: 4,
      shadowColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: daysLeft <= 7 
                ? [Colors.red.shade50, Colors.white]
                : [Colors.blue.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pets, 
                  color: daysLeft <= 7 ? Colors.red.shade400 : AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  daysLeft <= 0 ? 'Whelping Now!' : '$daysLeft Days Left',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: daysLeft <= 7 ? Colors.red.shade700 : AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const Spacer(),
            damAsync.when(
              data: (dam) => Text(
                'Dam: ${dam.callName}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              loading: () => const Text('Loading...'),
              error: (_, _) => const Text('Unknown Dam'),
            ),
            const SizedBox(height: 4),
            Text(
              'Due: ${DateFormat('MMM d, yyyy').format(whelpDate)}',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
