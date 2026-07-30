import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/delete_confirm_dialog.dart';
import '../../../domain/entities/dog.dart';
import '../../providers/pedigree_providers.dart';

class ShowsTab extends ConsumerWidget {
  final Dog dog;

  const ShowsTab({super.key, required this.dog});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showAsync = ref.watch(showRecordsProvider(dog.id));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Show & Title History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => context.push('/dog/${dog.id}/show/new'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Show'),
              ),
            ],
          ),
        ),
        Expanded(
          child: showAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: $e'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(showRecordsProvider(dog.id)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (records) {
              if (records.isEmpty) {
                return const Center(
                  child: Text('No show records found.', style: TextStyle(color: Colors.grey)),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index];
                  final dateStr = DateFormat('yyyy-MM-dd').format(record.date);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.amber.withValues(alpha: 0.2),
                        child: const Icon(Icons.emoji_events, color: Colors.amber),
                      ),
                      title: Text(record.eventName,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Date: $dateStr'),
                          if (record.judge != null && record.judge!.isNotEmpty)
                            Text('Judge: ${record.judge}'),
                          if (record.placement != null && record.placement!.isNotEmpty)
                            Text('Placement: ${record.placement}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.secondaryColor)),
                          if (record.titleAwarded != null && record.titleAwarded!.isNotEmpty)
                            Text('Title: ${record.titleAwarded}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor)),
                          if (record.notes != null && record.notes!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('Notes: ${record.notes}',
                                style: const TextStyle(fontStyle: FontStyle.italic)),
                          ],
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _deleteShowRecord(context, ref, record.id, dog.id),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _deleteShowRecord(BuildContext context, WidgetRef ref, int recordId, int dogId) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: 'Delete Record',
      message: 'Are you sure you want to delete this show record?',
    );

    if (confirmed && context.mounted) {
      try {
        final repo = ref.read(pedigreeRepositoryProvider);
        await repo.deleteShowRecord(recordId);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting record: $e')),
          );
        }
      }
    }
  }
}
