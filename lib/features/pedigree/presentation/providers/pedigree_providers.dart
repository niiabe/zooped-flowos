import 'package:drift/drift.dart' as drift;
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

// Photo Gallery Provider — Stream for live updates
final dogGalleryProvider = StreamProvider.family.autoDispose<List<DogPhoto>, int>((ref, dogId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.dogPhotos)
    ..where((p) => p.dogId.equals(dogId))
    ..orderBy([(p) => drift.OrderingTerm.desc(p.dateAdded)])).watch();
});

// Health Records Provider — Stream for live updates
final healthRecordsProvider = StreamProvider.family.autoDispose<List<HealthRecord>, int>((ref, dogId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.healthRecords)
    ..where((h) => h.dogId.equals(dogId))
    ..orderBy([(h) => drift.OrderingTerm.desc(h.date)])).watch();
});

final heatCyclesProvider = StreamProvider.family.autoDispose<List<HeatCycle>, int>((ref, dogId) {
  final db = ref.watch(databaseProvider);
  return db.watchHeatCycles(dogId);
});

// Show Records Provider — Stream for live updates
final showRecordsProvider = StreamProvider.family.autoDispose<List<ShowRecord>, int>((ref, dogId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.showRecords)
    ..where((s) => s.dogId.equals(dogId))
    ..orderBy([(s) => drift.OrderingTerm.desc(s.date)])).watch();
});

// All Litters Provider
final allLittersProvider = FutureProvider.autoDispose<List<domain_litter.Litter>>((ref) async {
  final repo = ref.watch(pedigreeRepositoryProvider);
  return await repo.getAllLitters();
});


