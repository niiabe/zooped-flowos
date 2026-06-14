import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../data/repositories/pedigree_repository_impl.dart';
import '../../domain/repositories/pedigree_repository.dart';
import '../../domain/use_cases/search_dogs_use_case.dart';
import '../../domain/use_cases/get_dog_by_id_use_case.dart';
import '../../domain/use_cases/insert_dog_use_case.dart';
import '../../domain/use_cases/update_dog_use_case.dart';
import '../../domain/use_cases/delete_dog_use_case.dart';
import '../../domain/use_cases/get_ancestors_use_case.dart';
import '../../domain/use_cases/get_dogs_for_dropdown_use_case.dart';
import '../../domain/use_cases/create_litter_use_case.dart';
import '../../domain/use_cases/delete_litter_use_case.dart';

// Database Provider (singleton via AppDatabase factory constructor)
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// Repository Provider
final pedigreeRepositoryProvider = Provider<PedigreeRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return PedigreeRepositoryImpl(database);
});

// Use Case Providers
final searchDogsUseCaseProvider = Provider<SearchDogsUseCase>((ref) {
  final repository = ref.watch(pedigreeRepositoryProvider);
  return SearchDogsUseCase(repository);
});

final getDogByIdUseCaseProvider = Provider<GetDogByIdUseCase>((ref) {
  final repository = ref.watch(pedigreeRepositoryProvider);
  return GetDogByIdUseCase(repository);
});

final insertDogUseCaseProvider = Provider<InsertDogUseCase>((ref) {
  final repository = ref.watch(pedigreeRepositoryProvider);
  return InsertDogUseCase(repository);
});

final updateDogUseCaseProvider = Provider<UpdateDogUseCase>((ref) {
  final repository = ref.watch(pedigreeRepositoryProvider);
  return UpdateDogUseCase(repository);
});

final deleteDogUseCaseProvider = Provider<DeleteDogUseCase>((ref) {
  final repository = ref.watch(pedigreeRepositoryProvider);
  return DeleteDogUseCase(repository);
});

final getAncestorsUseCaseProvider = Provider<GetAncestorsUseCase>((ref) {
  final repository = ref.watch(pedigreeRepositoryProvider);
  return GetAncestorsUseCase(repository);
});

final getDogsForDropdownUseCaseProvider = Provider<GetDogsForDropdownUseCase>((ref) {
  final repository = ref.watch(pedigreeRepositoryProvider);
  return GetDogsForDropdownUseCase(repository);
});

final createLitterUseCaseProvider = Provider<CreateLitterUseCase>((ref) {
  final repository = ref.watch(pedigreeRepositoryProvider);
  return CreateLitterUseCase(repository);
});

final deleteLitterUseCaseProvider = Provider<DeleteLitterUseCase>((ref) {
  final repository = ref.watch(pedigreeRepositoryProvider);
  return DeleteLitterUseCase(repository);
});
