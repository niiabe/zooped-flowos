import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/delete_confirm_dialog.dart';
import '../../../domain/entities/dog.dart';
import '../../providers/pedigree_providers.dart';

class OffspringTab extends ConsumerWidget {
  final Dog dog;

  const OffspringTab({super.key, required this.dog});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offspringAsync = ref.watch(dogOffspringProvider(dog.id));
    final littersAsync = ref.watch(dogLittersProvider(dog.id));

    if (offspringAsync.isLoading || littersAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (offspringAsync.hasError || littersAsync.hasError) {
      return const Center(child: Text('Error loading records'));
    }

    final litters = littersAsync.value ?? [];
    final offspring = offspringAsync.value ?? [];

    if (litters.isEmpty && offspring.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pets, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No litters or offspring recorded yet',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (litters.isNotEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Litters',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ...litters.map((litter) {
          final litterPuppies = offspring.where((p) => p.litterId == litter.id).toList();
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              initiallyExpanded: litterPuppies.isNotEmpty,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.family_restroom, color: AppTheme.primaryColor),
              ),
              title: Text(
                  'Whelped: ${DateFormat('yyyy-MM-dd').format(litter.whelpingDate)}'),
              subtitle: Text(
                  '${litter.totalPuppiesBorn} total puppies (${litterPuppies.length} registered here)'),
              children: [
                if (litterPuppies.isEmpty)
                  const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No offspring assigned to this litter yet.',
                          style: TextStyle(color: Colors.grey)))
                else
                  ...litterPuppies.map((puppy) => ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.pets, size: 16)),
                        title: Text(puppy.callName),
                        subtitle: Text(puppy.registeredName),
                        onTap: () => context.push('/dog/${puppy.id}'),
                      )),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _deleteLitter(context, ref, litter.id, dog.id),
                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                        label: const Text('Delete Litter',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        ...() {
          final unassigned = offspring.where((p) => p.litterId == null).toList();
          if (unassigned.isEmpty) return <Widget>[];
          return [
            const Padding(
              padding: EdgeInsets.only(top: 16, bottom: 8),
              child: Text('Unassigned Offspring',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ...unassigned.map((puppy) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.pets, size: 16)),
                    title: Text(puppy.callName),
                    subtitle: Text(puppy.registeredName),
                    onTap: () => context.push('/dog/${puppy.id}'),
                  ),
                ))
          ];
        }(),
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _deleteLitter(
      BuildContext context, WidgetRef ref, int litterId, int dogId) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: 'Delete Litter',
      message:
          'Are you sure you want to delete this litter? '
          'The puppies will not be deleted but they will no longer be associated with this litter.',
    );

    if (confirmed && context.mounted) {
      try {
        final repo = ref.read(pedigreeRepositoryProvider);
        await repo.deleteLitter(litterId);
        ref.invalidate(dogLittersProvider(dogId));
        ref.invalidate(dogOffspringProvider(dogId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Litter deleted successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}
