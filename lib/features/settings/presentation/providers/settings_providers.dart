import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../pedigree/presentation/providers/pedigree_providers.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/use_cases/get_kennel_profile_use_case.dart';
import '../../domain/use_cases/update_kennel_profile_use_case.dart';

// Settings Repository Provider (shares database with pedigree)
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return SettingsRepositoryImpl(database);
});

// Settings Use Case Providers
final getKennelProfileUseCaseProvider = Provider<GetKennelProfileUseCase>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return GetKennelProfileUseCase(repository);
});

final updateKennelProfileUseCaseProvider = Provider<UpdateKennelProfileUseCase>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return UpdateKennelProfileUseCase(repository);
});
