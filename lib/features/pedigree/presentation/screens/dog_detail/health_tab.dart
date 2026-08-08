import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/delete_confirm_dialog.dart';
import '../../../domain/entities/dog.dart';
import '../../providers/pedigree_providers.dart';

class HealthTab extends ConsumerStatefulWidget {
  final Dog dog;

  const HealthTab({super.key, required this.dog});

  @override
  ConsumerState<HealthTab> createState() => _HealthTabState();
}

class _HealthTabState extends ConsumerState<HealthTab> {
  String _searchQuery = '';
  String _filterType = 'All';

  static const _recordTypes = ['All', 'Vaccine', 'Deworming', 'Vet Visit', 'Heat Cycle'];

  @override
  Widget build(BuildContext context) {
    final healthAsync = ref.watch(healthRecordsProvider(widget.dog.id));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Medical History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => context.push('/dog/${widget.dog.id}/health/new'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Record'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search records...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 110,
                child: DropdownButtonFormField<String>(
                  value: _filterType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    isDense: true,
                  ),
                  items: _recordTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (value) => setState(() => _filterType = value ?? 'All'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
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
                    onPressed: () => ref.invalidate(healthRecordsProvider(widget.dog.id)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (records) {
              final filtered = records.where((r) {
                final matchesSearch = _searchQuery.isEmpty ||
                    r.recordType.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    (r.notes?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
                final matchesType = _filterType == 'All' || r.recordType == _filterType;
                return matchesSearch && matchesType;
              }).toList();

              if (records.isEmpty) {
                return const Center(
                  child: Text('No health records found.', style: TextStyle(color: Colors.grey)),
                );
              }

              if (filtered.isEmpty) {
                return const Center(
                  child: Text('No records match your search.', style: TextStyle(color: Colors.grey)),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final record = filtered[index];
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
                        onPressed: () => _deleteHealthRecord(context, ref, record.id, widget.dog.id),
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
