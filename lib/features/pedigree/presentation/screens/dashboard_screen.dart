import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/dog.dart';
import '../providers/pedigree_providers.dart';
import '../providers/shared_providers.dart';
import '../widgets/dog_list_item.dart';
import '../widgets/upcoming_whelping_widget.dart';

final _searchQueryProvider = StateProvider<String>((ref) => '');
final _debouncedSearchProvider = Provider<String>((ref) {
  return ref.watch(_searchQueryProvider);
});

final dogsProvider = FutureProvider.autoDispose<List<Dog>>((ref) async {
  ref.keepAlive();
  final query = ref.watch(_debouncedSearchProvider);
  final filter = ref.watch(dashboardFilterProvider);
  final repo = ref.watch(pedigreeRepositoryProvider);

  if (query.isNotEmpty) {
    return await repo.searchDogs(query);
  }
  return await repo.getFilteredDogs(sex: filter.sex, sortBy: filter.sortBy);
});

class _SearchDebouncer {
  Timer? _timer;
  void call(String value, void Function(String) onDone) {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 300), () => onDone(value));
  }
  void dispose() => _timer?.cancel();
}

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  final _debouncer = _SearchDebouncer();

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dogsAsync = ref.watch(dogsProvider);
    final padding = Responsive.padding(context);
    final isTablet = Responsive.isTablet(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        title: Image.asset(
          'assets/images/logo.png',
          height: 32,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Text('ZooPed'),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.family_restroom),
            tooltip: 'View Litters',
            onPressed: () => context.push('/litters'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          const UpcomingWhelpingWidget(),
          Padding(
            padding: EdgeInsets.all(padding),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search dogs...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(_searchQueryProvider.notifier).state = '';
                                FocusScope.of(context).unfocus();
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      _debouncer(value, (v) {
                        if (mounted) {
                          ref.read(_searchQueryProvider.notifier).state = v;
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.tune),
                  onPressed: () => _showFilterBottomSheet(context),
                  tooltip: 'Filter List',
                ),
              ],
            ),
          ),
          _buildActiveFilterChips(),
          Expanded(
            child: dogsAsync.when(
              loading: () => ListView.builder(
                padding: EdgeInsets.all(padding),
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Card(
                      margin: EdgeInsets.only(bottom: padding),
                      child: ListTile(
                        leading: const CircleAvatar(radius: 24),
                        title: Container(
                          height: 16,
                          width: double.infinity,
                          color: Colors.white,
                        ),
                        subtitle: Container(
                          height: 12,
                          width: 100,
                          color: Colors.white,
                          margin: const EdgeInsets.only(top: 8),
                        ),
                      ),
                    ),
                  );
                },
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $e'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(dogsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (dogs) {
                if (dogs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.pets,
                          size: isTablet ? 80.0 : 64.0,
                          color: Colors.grey.shade300,
                        ),
                        SizedBox(height: padding),
                        Text(
                          'No dogs found',
                          style: TextStyle(
                            fontSize: isTablet ? 20.0 : 16.0,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          'Tap + to add your first dog',
                          style: TextStyle(
                            fontSize: isTablet ? 16.0 : 14.0,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (isTablet) {
                  return GridView.builder(
                    padding: EdgeInsets.all(padding),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: Responsive.gridCrossAxisCount(context),
                      childAspectRatio: 2.5,
                      crossAxisSpacing: padding,
                      mainAxisSpacing: padding * 0.5,
                    ),
                    itemCount: dogs.length,
                    itemBuilder: (context, index) {
                      final dog = dogs[index];
                      return DogListItem(
                        dog: dog,
                        onTap: () => context.push('/dog/${dog.id}'),
                      );
                    },
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: padding * 0.5),
                  itemCount: dogs.length,
                  itemBuilder: (context, index) {
                    final dog = dogs[index];
                    return DogListItem(
                      dog: dog,
                      onTap: () => context.push('/dog/${dog.id}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddOptions(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.pets),
              title: const Text('Add Dog'),
              onTap: () {
                Navigator.pop(context);
                context.push('/dog/new');
              },
            ),
            ListTile(
              leading: const Icon(Icons.family_restroom),
              title: const Text('Register Litter'),
              onTap: () {
                Navigator.pop(context);
                context.push('/litter/new');
              },
            ),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('View Litters'),
              onTap: () {
                Navigator.pop(context);
                context.push('/litters');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.science, color: Colors.purple),
              title: const Text('Matchmaker Predictions'),
              onTap: () {
                Navigator.pop(context);
                context.push('/matchmaker');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const _FilterBottomSheet(),
    );
  }

  Widget _buildActiveFilterChips() {
    final filter = ref.watch(dashboardFilterProvider);
    if (filter.sex == 'All' && filter.sortBy == 'Name (A-Z)') return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0).copyWith(bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          if (filter.sex != 'All')
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Chip(
                label: Text(filter.sex),
                onDeleted: () => ref.read(dashboardFilterProvider.notifier).state = filter.copyWith(sex: 'All'),
                visualDensity: VisualDensity.compact,
              ),
            ),
          if (filter.sortBy != 'Name (A-Z)')
            Chip(
              label: Text('Sort: ${filter.sortBy}'),
              onDeleted: () => ref.read(dashboardFilterProvider.notifier).state = filter.copyWith(sortBy: 'Name (A-Z)'),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

class _FilterBottomSheet extends ConsumerWidget {
  const _FilterBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(dashboardFilterProvider);
    final notifier = ref.read(dashboardFilterProvider.notifier);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Filter & Sort', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),
          const Text('Sex', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'All', label: Text('All')),
              ButtonSegment(value: 'Male', label: Text('Male')),
              ButtonSegment(value: 'Female', label: Text('Female')),
            ],
            selected: {filter.sex},
            onSelectionChanged: (set) => notifier.state = filter.copyWith(sex: set.first),
            style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
          const SizedBox(height: 24),
          const Text('Sort By', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['Name (A-Z)', 'Recent', 'Age (Youngest)'].map((sortOption) {
              return ChoiceChip(
                label: Text(sortOption),
                selected: filter.sortBy == sortOption,
                onSelected: (selected) {
                  if (selected) notifier.state = filter.copyWith(sortBy: sortOption);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Apply'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
