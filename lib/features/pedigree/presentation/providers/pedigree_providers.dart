import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/dog.dart' as domain;
import '../../domain/entities/litter.dart' as domain_litter;
import '../../../../core/database/app_database.dart';
import '../../data/repositories/pedigree_repository_impl.dart';
import '../../domain/repositories/pedigree_repository.dart';
import '../../domain/usecases/calculate_coi_usecase.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final pedigreeRepositoryProvider = Provider<PedigreeRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return PedigreeRepositoryImpl(database);
});

final calculateCoiUseCaseProvider = Provider<CalculateCoiUseCase>((ref) {
  return CalculateCoiUseCase();
});

final dogByIdProvider = FutureProvider.family.autoDispose<domain.Dog, int>((ref, dogId) async {
  final repo = ref.watch(pedigreeRepositoryProvider);
  return await repo.getDogByIdFlat(dogId);
});

final getDogWithPedigreeProvider = FutureProvider.family.autoDispose<domain.Dog, int>((ref, dogId) async {
  final repo = ref.watch(pedigreeRepositoryProvider);
  return await repo.getDogByIdWithPedigree(dogId);
});

// Family Providers for Dog Details
final dogOffspringProvider = FutureProvider.family.autoDispose<List<domain.Dog>, int>((ref, dogId) async {
  final repo = ref.watch(pedigreeRepositoryProvider);
  return await repo.getOffspringForDog(dogId);
});

final dogLittersProvider = FutureProvider.family.autoDispose<List<domain_litter.Litter>, int>((ref, dogId) async {
  final repo = ref.watch(pedigreeRepositoryProvider);
  return await repo.getLittersForDog(dogId);
});

// Photo Gallery Provider
final dogGalleryProvider = FutureProvider.family.autoDispose<List<DogPhoto>, int>((ref, dogId) async {
  final db = ref.watch(databaseProvider);
  return await db.getPhotosForDog(dogId);
});

// Health Records Provider
final healthRecordsProvider = FutureProvider.family.autoDispose<List<HealthRecord>, int>((ref, dogId) async {
  final db = ref.watch(databaseProvider);
  return await db.getHealthRecordsForDog(dogId);
});

final heatCyclesProvider = StreamProvider.family.autoDispose<List<HeatCycle>, int>((ref, dogId) {
  final db = ref.watch(databaseProvider);
  return db.watchHeatCycles(dogId);
});

// Show Records Provider
final showRecordsProvider = FutureProvider.family.autoDispose<List<ShowRecord>, int>((ref, dogId) async {
  final db = ref.watch(databaseProvider);
  return await db.getShowRecordsForDog(dogId);
});


