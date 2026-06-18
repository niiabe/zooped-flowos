import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../settings/domain/entities/kennel_profile.dart';
import '../../domain/entities/dog.dart';
import 'pedigree_providers.dart';

final siresProvider = FutureProvider.autoDispose<List<Dog>>((ref) async {
  final repo = ref.watch(pedigreeRepositoryProvider);
  return await repo.getDogsForDropdown('Male');
});

final damsProvider = FutureProvider.autoDispose<List<Dog>>((ref) async {
  final repo = ref.watch(pedigreeRepositoryProvider);
  return await repo.getDogsForDropdown('Female');
});

final kennelProfileProvider = FutureProvider.autoDispose<KennelProfile>((ref) async {
  ref.keepAlive();
  final useCase = ref.watch(getKennelProfileUseCaseProvider);
  return await useCase();
});

class DashboardFilter {
  final String sex;
  final String sortBy;

  const DashboardFilter({
    this.sex = 'All',
    this.sortBy = 'Name (A-Z)',
  });

  DashboardFilter copyWith({
    String? sex,
    String? sortBy,
  }) {
    return DashboardFilter(
      sex: sex ?? this.sex,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

final dashboardFilterProvider = StateProvider<DashboardFilter>((ref) {
  return const DashboardFilter();
});
