import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../providers/pedigree_providers.dart';

class _LitterWithParents {
  final int id;
  final int sireId;
  final int damId;
  final String sireName;
  final String damName;
  final DateTime? matingDate;
  final DateTime whelpingDate;
  final int puppiesBornAlive;
  final int puppiesStillborn;
  final String? notes;

  const _LitterWithParents({
    required this.id,
    required this.sireId,
    required this.damId,
    required this.sireName,
    required this.damName,
    this.matingDate,
    required this.whelpingDate,
    this.puppiesBornAlive = 0,
    this.puppiesStillborn = 0,
    this.notes,
  });

  int get totalPuppies => puppiesBornAlive + puppiesStillborn;
}

final _littersWithParentsProvider = FutureProvider.autoDispose<List<_LitterWithParents>>((ref) async {
  final repo = ref.read(pedigreeRepositoryProvider);
  final litters = await repo.getAllLitters();
  final results = <_LitterWithParents>[];

  final parentIds = <int>{};
  for (final litter in litters) {
    if (litter.sireId > 0) parentIds.add(litter.sireId);
    if (litter.damId > 0) parentIds.add(litter.damId);
  }

  final parentNames = parentIds.isNotEmpty
      ? await repo.getDogNamesByIds(parentIds.toList())
      : <int, String>{};

  for (final litter in litters) {
    results.add(_LitterWithParents(
      id: litter.id,
      sireId: litter.sireId,
      damId: litter.damId,
      sireName: parentNames[litter.sireId] ?? 'Unknown',
      damName: parentNames[litter.damId] ?? 'Unknown',
      matingDate: litter.matingDate,
      whelpingDate: litter.whelpingDate,
      puppiesBornAlive: litter.puppiesBornAlive,
      puppiesStillborn: litter.puppiesStillborn,
      notes: litter.notes,
    ));
  }

  results.sort((a, b) => b.whelpingDate.compareTo(a.whelpingDate));
  return results;
});

class LitterListScreen extends ConsumerWidget {
  const LitterListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final littersAsync = ref.watch(_littersWithParentsProvider);
    final padding = Responsive.padding(context);
    final isTablet = Responsive.isTablet(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Litters'),
      ),
      body: littersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(_littersWithParentsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (litters) {
          if (litters.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.family_restroom, size: isTablet ? 80.0 : 64.0, color: Colors.grey.shade300),
                  SizedBox(height: padding),
                  Text(
                    'No litters registered yet',
                    style: TextStyle(fontSize: isTablet ? 20.0 : 16.0, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Register a litter from the dashboard',
                    style: TextStyle(fontSize: isTablet ? 16.0 : 14.0, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(padding),
            itemCount: litters.length,
            itemBuilder: (context, index) {
              final litter = litters[index];
              return Card(
                key: ValueKey('litter_${litter.id}'),
                margin: EdgeInsets.only(bottom: padding),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    final puppiesCount = litter.totalPuppies;
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('Litter #${litter.id}'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _detailRow('Sire', litter.sireName),
                            _detailRow('Dam', litter.damName),
                            if (litter.matingDate != null)
                              _detailRow('Mating', DateFormat('yyyy-MM-dd').format(litter.matingDate!)),
                            _detailRow('Whelping', DateFormat('yyyy-MM-dd').format(litter.whelpingDate)),
                            _detailRow('Puppies Born', '$puppiesCount (${litter.puppiesBornAlive} alive, ${litter.puppiesStillborn} stillborn)'),
                            if (litter.notes != null && litter.notes!.isNotEmpty)
                              _detailRow('Notes', litter.notes!),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.family_restroom, color: AppTheme.primaryColor, size: 28),
                        ),
                        SizedBox(width: padding),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${litter.sireName} × ${litter.damName}',
                                style: TextStyle(
                                  fontSize: isTablet ? 16.0 : 14.0,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.secondaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${DateFormat('yyyy-MM-dd').format(litter.whelpingDate)} • ${litter.totalPuppies} puppy${litter.totalPuppies == 1 ? '' : 'ies'}',
                                style: TextStyle(fontSize: isTablet ? 14.0 : 13.0, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.grey.shade400),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/litter/new'),
        heroTag: 'addLitter',
        icon: const Icon(Icons.add),
        label: const Text('Register Litter'),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
