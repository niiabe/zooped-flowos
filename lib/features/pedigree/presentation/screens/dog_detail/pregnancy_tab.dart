import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/delete_confirm_dialog.dart';
import '../../../domain/entities/dog.dart';
import '../../../domain/entities/litter.dart';
import '../../providers/pedigree_providers.dart';

class PregnancyTab extends ConsumerStatefulWidget {
  final Dog dog;

  const PregnancyTab({super.key, required this.dog});

  @override
  ConsumerState<PregnancyTab> createState() => _PregnancyTabState();
}

class _PregnancyTabState extends ConsumerState<PregnancyTab> {
  @override
  Widget build(BuildContext context) {
    final padding = 16.0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pregnancy Tracker',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => _showAddMatingDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Log Mating'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Consumer(
            builder: (context, ref, _) {
              final matingsAsync = ref.watch(_matingsProvider(widget.dog.id));

              return matingsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $e'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(_matingsProvider(widget.dog.id)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (matings) {
                  if (matings.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pets, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No mating records found.',
                              style: TextStyle(color: Colors.grey)),
                          SizedBox(height: 8),
                          Text('Tap "Log Mating" to record a breeding.',
                              style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: matings.length,
                    itemBuilder: (context, index) {
                      final mating = matings[index];
                      return _buildMatingCard(mating);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMatingCard(Map<String, dynamic> mating) {
    final matingDate = mating['matingDate'] as DateTime;
    final expectedWhelpDate = matingDate.add(const Duration(days: 63));
    final litter = mating['litter'] as Litter?;
    final partner = mating['partner'] as Dog?;
    final now = DateTime.now();
    final daysUntilWhelp = expectedWhelpDate.difference(now).inDays;
    final isOverdue = daysUntilWhelp < 0;
    final isWhelped = litter != null;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isWhelped) {
      statusColor = Colors.green;
      statusText = 'Whelped';
      statusIcon = Icons.check_circle;
    } else if (isOverdue) {
      statusColor = Colors.orange;
      statusText = '${-daysUntilWhelp} days overdue';
      statusIcon = Icons.warning;
    } else if (daysUntilWhelp <= 10) {
      statusColor = Colors.red;
      statusText = '$daysUntilWhelp days left';
      statusIcon = Icons.pregnant_woman;
    } else {
      statusColor = Colors.blue;
      statusText = '$daysUntilWhelp days left';
      statusIcon = Icons.pregnant_woman;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          'Mating with ${partner?.callName ?? "Unknown"}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${DateFormat('MMM d, yyyy').format(matingDate)}'),
            Row(
              children: [
                Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: 4),
                Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Mating Date', DateFormat('MMM d, yyyy').format(matingDate)),
                _buildInfoRow('Expected Whelp', DateFormat('MMM d, yyyy').format(expectedWhelpDate)),
                if (litter != null) ...[
                  const Divider(),
                  _buildInfoRow('Whelped Date', DateFormat('MMM d, yyyy').format(litter.whelpingDate)),
                  _buildInfoRow('Puppies Born', '${litter.puppiesBornAlive}'),
                  if (litter.puppiesStillborn != null && litter.puppiesStillborn! > 0)
                    _buildInfoRow('Stillborn', '${litter.puppiesStillborn}'),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/litter/${litter.id}/health'),
                      icon: const Icon(Icons.medical_services, size: 18),
                      label: const Text('View Litter Health Records'),
                    ),
                  ),
                ] else ...[
                  const Divider(),
                  const Text(
                    'Pregnancy Progress',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: ((63 - daysUntilWhelp) / 63).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${((63 - daysUntilWhelp) / 63 * 100).clamp(0, 100).toStringAsFixed(0)}% complete (${63 - daysUntilWhelp} of 63 days)',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!isWhelped)
                      TextButton(
                        onPressed: () => _showLogWhelpDialog(mating),
                        child: const Text('Log Whelping'),
                      ),
                    TextButton(
                      onPressed: () => _deleteMating(mating['id'] as int),
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showAddMatingDialog(BuildContext context) {
    DateTime selectedDate = DateTime.now();
    int? selectedPartnerId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Log Mating'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Mating Date'),
                    subtitle: Text(DateFormat('MMM d, yyyy').format(selectedDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => selectedDate = date);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<Dog>>(
                    future: ref.read(pedigreeRepositoryProvider).getDogsForDropdown(
                        widget.dog.sex == 'Male' ? 'Female' : 'Male'),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const CircularProgressIndicator();
                      final partners = snapshot.data!;
                      return DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Partner',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedPartnerId,
                        items: partners.map((d) => DropdownMenuItem(
                          value: d.id,
                          child: Text('${d.callName} (${d.registeredName})'),
                        )).toList(),
                        onChanged: (value) => setState(() => selectedPartnerId = value),
                      );
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
                  onPressed: selectedPartnerId == null
                      ? null
                      : () async {
                          try {
                            final repo = ref.read(pedigreeRepositoryProvider);
                            await repo.addMating(
                              widget.dog.sex == 'Male' ? widget.dog.id : selectedPartnerId!,
                              widget.dog.sex == 'Male' ? selectedPartnerId! : widget.dog.id,
                              selectedDate,
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              ref.invalidate(_matingsProvider(widget.dog.id));
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error logging mating: $e')),
                              );
                            }
                          }
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

  void _showLogWhelpDialog(Map<String, dynamic> mating) {
    // Navigate to litter form with pre-filled mating data
    final matingDate = mating['matingDate'] as DateTime;
    final partner = mating['partner'] as Dog?;

    context.push('/litter/new', extra: {
      'sireId': widget.dog.sex == 'Male' ? widget.dog.id : partner?.id,
      'damId': widget.dog.sex == 'Female' ? widget.dog.id : partner?.id,
      'matingDate': matingDate,
    });
  }

  Future<void> _deleteMating(int matingId) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: 'Delete Mating Record',
      message: 'Are you sure you want to delete this mating record?',
    );

    if (confirmed && context.mounted) {
      try {
        final repo = ref.read(pedigreeRepositoryProvider);
        await repo.deleteMating(matingId);
        ref.invalidate(_matingsProvider(widget.dog.id));
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting mating: $e')),
          );
        }
      }
    }
  }
}

final _matingsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, int>((ref, dogId) async {
  final repo = ref.watch(pedigreeRepositoryProvider);
  final matings = await repo.getMatingsForDog(dogId);
  final allLitters = await repo.getAllLitters();
  
  final result = <Map<String, dynamic>>[];
  for (final mating in matings) {
    final partnerId = mating.sireId == dogId ? mating.damId : mating.sireId;
    final partner = await repo.getDogByIdFlat(partnerId);
    
    // Check if a litter exists for this mating
    Litter? litter;
    for (final l in allLitters) {
      if (l.sireId == mating.sireId && l.damId == mating.damId && l.matingDate == mating.matingDate) {
        litter = l;
        break;
      }
    }
    
    result.add({
      'id': mating.id,
      'matingDate': mating.matingDate,
      'partner': partner,
      'litter': litter,
      'notes': mating.notes,
    });
  }
  
  return result;
});
