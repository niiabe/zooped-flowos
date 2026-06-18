import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/app_database.dart' hide Dog;
import '../../domain/entities/dog.dart';
import '../providers/pedigree_providers.dart';

final _femalesProvider = FutureProvider.autoDispose<List<Dog>>((ref) async {
  final repo = ref.watch(pedigreeRepositoryProvider);
  return await repo.getDogsForDropdown('Female');
});

class HeatTrackerTab extends ConsumerWidget {
  const HeatTrackerTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final femalesAsync = ref.watch(_femalesProvider);

    return femalesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (females) {
        if (females.isEmpty) {
          return const Center(child: Text('No female dogs found.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: females.length,
          itemBuilder: (context, index) {
            final dog = females[index];
            return _buildFemaleCard(context, ref, dog);
          },
        );
      },
    );
  }

  Widget _buildFemaleCard(BuildContext context, WidgetRef ref, Dog dog) {
    final db = ref.watch(databaseProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ExpansionTile(
        title: Text(dog.callName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Tap to view heat cycles'),
        leading: const CircleAvatar(
          backgroundColor: Colors.pinkAccent,
          child: Icon(Icons.female, color: Colors.white),
        ),
        children: [
          Consumer(
            builder: (context, ref, _) {
              final heatCyclesAsync = ref.watch(heatCyclesProvider(dog.id));
              
              return heatCyclesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
                ),
                data: (cycles) {
                  return Column(
                    children: [
                      if (cycles.isNotEmpty)
                        ...cycles.map((cycle) => ListTile(
                              title: Text('Started: ${DateFormat('MMM d, yyyy').format(cycle.startDate)}'),
                              subtitle: cycle.endDate != null 
                                  ? Text('Ended: ${DateFormat('MMM d, yyyy').format(cycle.endDate!)}')
                                  : const Text('Ongoing'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => db.deleteHeatCycle(cycle.id),
                              ),
                            )),
                      if (cycles.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No heat cycles logged yet.'),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Log Heat Cycle'),
                          onPressed: () => _showAddHeatDialog(context, db, dog.id),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          )
        ],
      ),
    );
  }

  void _showAddHeatDialog(BuildContext context, AppDatabase db, int dogId) {
    DateTime? selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Log Heat Cycle'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Start Date'),
                    subtitle: Text(DateFormat('MMM d, yyyy').format(selectedDate!)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate!,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => selectedDate = date);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await db.addHeatCycle(HeatCyclesCompanion.insert(
                      dogId: dogId,
                      startDate: selectedDate!,
                    ));
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
