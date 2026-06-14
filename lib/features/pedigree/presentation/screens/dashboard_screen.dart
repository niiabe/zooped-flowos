import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/responsive.dart';
import '../providers/pedigree_providers.dart';
import '../widgets/dog_list_item.dart';

final _searchQueryProvider = StateProvider<String>((ref) => '');

final _dogsProvider = FutureProvider.autoDispose<List>((ref) async {
  final query = ref.watch(_searchQueryProvider);
  final useCase = ref.watch(searchDogsUseCaseProvider);
  return await useCase(query);
});

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dogsAsync = ref.watch(_dogsProvider);
    final padding = Responsive.padding(context);
    final isTablet = Responsive.isTablet(context);

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/AppBar.png',
          height: 48,
          cacheHeight: 96,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Text('ZooPed'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(padding),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search dogs by name, registered name, or microchip...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(_searchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                ref.read(_searchQueryProvider.notifier).state = value;
              },
            ),
          ),
          Expanded(
            child: dogsAsync.when(
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
                      onPressed: () => ref.invalidate(_dogsProvider),
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
          ],
        ),
      ),
    );
  }
}
