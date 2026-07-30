import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/delete_confirm_dialog.dart';
import '../../../domain/entities/dog.dart';
import '../../providers/pedigree_providers.dart';

class HealthTab extends ConsumerWidget {
  final Dog dog;

  const HealthTab({super.key, required this.dog});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(healthRecordsProvider(dog.id));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Medical History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => context.push('/dog/${dog.id}/health/new'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Record'),
              ),
            ],
          ),
        ),
        Expanded(
          child: healthAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: $e'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(healthRecordsProvider(dog.id)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (records) {
              if (records.isEmpty) {
                return const Center(
                  child: Text('No health records found.', style: TextStyle(color: Colors.grey)),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index];
                  final dateStr = DateFormat('yyyy-MM-dd').format(record.date);
                  final nextDueStr = record.nextDueDate != null
                      ? DateFormat('yyyy-MM-dd').format(record.nextDueDate!)
                      : 'None';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                        child: Icon(
                          record.recordType == 'Vaccine'
                              ? Icons.vaccines
                              : record.recordType == 'Vet Visit'
                                  ? Icons.local_hospital
                                  : record.recordType == 'Deworming'
                                      ? Icons.medication
                                      : Icons.favorite,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      title: Text('${record.recordType} - $dateStr'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (record.notes != null && record.notes!.isNotEmpty)
                            Text(record.notes!),
                          const SizedBox(height: 4),
                          Text('Next Due: $nextDueStr',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _deleteHealthRecord(context, ref, record.id, dog.id),
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

  Future<void> _deleteHealthRecord(BuildContext context, WidgetRef ref, int recordId, int dogId) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: 'Delete Record',
      message: 'Are you sure you want to delete this health record?',
    );

    if (confirmed && context.mounted) {
      try {
        final repo = ref.read(pedigreeRepositoryProvider);
        await repo.deleteHealthRecord(recordId);
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
