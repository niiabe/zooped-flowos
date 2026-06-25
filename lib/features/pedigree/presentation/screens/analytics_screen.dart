import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/error/error_handler.dart';
import '../providers/pedigree_providers.dart';

class KennelStats {
  final int totalDogs;
  final int totalMales;
  final int totalFemales;
  final int totalLitters;
  final double averageLitterSize;
  final Map<String, int> breedCounts;

  KennelStats({
    required this.totalDogs,
    required this.totalMales,
    required this.totalFemales,
    required this.totalLitters,
    required this.averageLitterSize,
    required this.breedCounts,
  });
}

final analyticsProvider = StreamProvider.autoDispose<KennelStats>((ref) async* {
  final db = ref.watch(databaseProvider);

  final dogsStream = db.select(db.dogs).watch();
  final littersStream = db.select(db.litters).watch();

  await for (final _ in Rx.combineLatest2(dogsStream, littersStream, (a, b) => null)) {
    final dogs = await db.select(db.dogs).get();
    final litters = await db.select(db.litters).get();

    final males = dogs.where((d) => d.sex == 'Male').length;
    final females = dogs.where((d) => d.sex == 'Female').length;

    double avgLitterSize = 0;
    if (litters.isNotEmpty) {
      final int totalPuppies = litters.fold<int>(0, (sum, litter) => sum + litter.puppiesBornAlive + litter.puppiesStillborn);
      avgLitterSize = totalPuppies / litters.length;
    }

    final breedCounts = <String, int>{};
    for (final dog in dogs) {
      if (dog.breed != null && dog.breed!.isNotEmpty) {
        breedCounts[dog.breed!] = (breedCounts[dog.breed!] ?? 0) + 1;
      } else {
        breedCounts['Unknown'] = (breedCounts['Unknown'] ?? 0) + 1;
      }
    }

    yield KennelStats(
      totalDogs: dogs.length,
      totalMales: males,
      totalFemales: females,
      totalLitters: litters.length,
      averageLitterSize: avgLitterSize,
      breedCounts: breedCounts,
    );
  }
});

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final padding = Responsive.padding(context);
    final statsAsync = ref.watch(analyticsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Kennel Analytics 📊'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.secondaryColor,
        elevation: 0,
      ),
      body: statsAsync.when(
        data: (stats) {
          if (stats.totalDogs == 0) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 80.0,
                    color: Colors.grey.shade300,
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 0.9, end: 1.1, duration: 1.seconds, curve: Curves.easeInOut),
                  const SizedBox(height: 16.0),
                  Text(
                    'No Data Available',
                    style: TextStyle(
                      fontSize: 20.0,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Add dogs to see kennel statistics',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ).animate().fadeIn(duration: 500.ms),
            );
          }
          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatCard(
                  title: 'Total Dogs in Kennel',
                  value: stats.totalDogs.toString(),
                  icon: Icons.pets,
                  color: Colors.blue,
                ).animate().fadeIn(delay: 0.ms).slideX(begin: 0.1, end: 0.0),
                SizedBox(height: padding),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Males',
                        value: stats.totalMales.toString(),
                        icon: Icons.male,
                        color: Colors.blue.shade300,
                      ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1, end: 0.0),
                    ),
                    SizedBox(width: padding),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Females',
                        value: stats.totalFemales.toString(),
                        icon: Icons.female,
                        color: Colors.pink.shade300,
                      ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1, end: 0.0),
                    ),
                  ],
                ),
                SizedBox(height: padding),
                _buildProgressBar(stats.totalMales, stats.totalFemales).animate().fadeIn(delay: 200.ms),
                SizedBox(height: padding),
                _buildStatCard(
                  title: 'Total Litters Whelped',
                  value: stats.totalLitters.toString(),
                  icon: Icons.family_restroom,
                  color: Colors.green,
                ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1, end: 0.0),
                SizedBox(height: padding),
                _buildStatCard(
                  title: 'Average Litter Size',
                  value: stats.averageLitterSize.toStringAsFixed(1),
                  icon: Icons.calculate,
                  color: Colors.purple,
                ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1, end: 0.0),
                SizedBox(height: padding),
                _buildBreedDistribution(stats.breedCounts).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0.0),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading stats: ${ErrorHandler.getUserFriendlyMessage(e)}')),
      ),
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color color}) {
    return Card(
      elevation: 4,
      shadowColor: color.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(int males, int females) {
    final int total = males + females;
    if (total == 0) return const SizedBox.shrink();

    return Column(
      children: [
        const Text('Sex Distribution', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              Expanded(
                flex: males,
                child: Container(height: 20, color: Colors.blue.shade300),
              ),
              Expanded(
                flex: females,
                child: Container(height: 20, color: Colors.pink.shade300),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBreedDistribution(Map<String, int> breedCounts) {
    if (breedCounts.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      shadowColor: Colors.orange.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.pets, color: Colors.orange),
                SizedBox(width: 8),
                Text('Breed Distribution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 16),
            ...breedCounts.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key, style: const TextStyle(fontSize: 16)),
                    Text(entry.value.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
