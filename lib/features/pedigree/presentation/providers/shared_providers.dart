import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../settings/domain/entities/kennel_profile.dart';
import '../../domain/entities/dog.dart';
import 'pedigree_providers.dart';

final siresProvider = FutureProvider<List<Dog>>((ref) async {
  final useCase = ref.watch(getDogsForDropdownUseCaseProvider);
  return await useCase('Male');
});

final damsProvider = FutureProvider<List<Dog>>((ref) async {
  final useCase = ref.watch(getDogsForDropdownUseCaseProvider);
  return await useCase('Female');
});

final kennelProfileProvider = FutureProvider<KennelProfile>((ref) async {
  final useCase = ref.watch(getKennelProfileUseCaseProvider);
  return await useCase();
});
