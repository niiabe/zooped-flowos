import '../../domain/entities/dog.dart' as domain;
import '../../domain/entities/litter.dart' as domain_litter;
import '../../domain/repositories/pedigree_repository.dart';
import '../../../../core/database/app_database.dart';
import 'package:drift/drift.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/services/file_storage_service.dart';
import '../models/dog_model.dart';
import '../models/litter_model.dart';

class PedigreeRepositoryImpl implements PedigreeRepository {
  final AppDatabase _database;

  PedigreeRepositoryImpl(this._database);

  @override
  Future<domain.Dog> getDogById(int id) async {
    final data = await _database.getDogById(id);
    final parentIds = [if (data.sireId != null) data.sireId!, if (data.damId != null) data.damId!];
    final parentMap = parentIds.isNotEmpty
        ? {for (final d in await _database.getDogsByIds(parentIds)) d.id: d}
        : <int, Dog>{};
    return data.toDomain(
      sire: data.sireId != null ? parentMap[data.sireId]?.toDomain() : null,
      dam: data.damId != null ? parentMap[data.damId]?.toDomain() : null,
    );
  }

  @override
  Future<domain.Dog> getDogByIdFlat(int id) async {
    final data = await _database.getDogById(id);
    return data.toDomain();
  }

  @override
  Future<domain.Dog> getDogByIdWithPedigree(int id) async {
    final ancestors = await _database.getAncestorsForPedigree(id, 3);
    final dogMap = {for (final d in ancestors) d.id: d};
    final rootData = dogMap[id];
    if (rootData == null) throw Exception('Dog not found');
    return _buildTree(rootData, dogMap);
  }

  Future<List<domain.Dog>> getDogsByIds(List<int> ids) async {
    final dogsData = await _database.getDogsByIds(ids);
    return dogsData.map((dog) => dog.toDomain()).toList();
  }

  @override
  Future<Map<int, String>> getDogNamesByIds(List<int> ids) async {
    final dogsData = await _database.getDogsByIds(ids);
    return {for (final d in dogsData) d.id: d.callName};
  }

  domain.Dog _buildTree(Dog data, Map<int, Dog> map) {
    return data.toDomain(
      sire: data.sireId != null && map.containsKey(data.sireId)
          ? _buildTree(map[data.sireId]!, map)
          : null,
      dam: data.damId != null && map.containsKey(data.damId)
          ? _buildTree(map[data.damId]!, map)
          : null,
    );
  }

  @override
  Future<List<domain.Dog>> searchDogs(String query) async {
    final dogsData = await _database.searchDogs(query);
    return dogsData.map((dog) => dog.toDomain()).toList();
  }

  @override
  Future<List<domain.Dog>> getDogsForDropdown(String sex) async {
    final dogsData = await _database.getDogsForDropdown(sex);
    return dogsData.map((dog) => dog.toDomain()).toList();
  }

  @override
  Future<List<domain.Dog>> getAllDogs() async {
    final dogsData = await _database.getAllDogs();
    return dogsData.map((dog) => dog.toDomain()).toList();
  }

  @override
  Future<List<domain.Dog>> getFilteredDogs({String? sex, String? sortBy}) async {
    final dogsData = await _database.getFilteredDogs(sex: sex, sortBy: sortBy);
    return dogsData.map((dog) => dog.toDomain()).toList();
  }

  @override
  Stream<List<domain.Dog>> watchFilteredDogs({String? sex, String? sortBy}) {
    return _database.watchFilteredDogs(sex: sex, sortBy: sortBy).map(
      (dogsData) => dogsData.map((dog) => dog.toDomain()).toList(),
    );
  }

  @override
  Future<int> insertDog(domain.Dog dog, {int? sireId, int? damId}) async {
    try {
      return await _database.insertDog(dog.toCompanion(overrideSireId: sireId, overrideDamId: damId));
    } catch (e) {
      throw DatabaseException('Failed to insert dog: $e', e);
    }
  }

  @override
  Future<void> updateDog(domain.Dog dog, {int? sireId, int? damId}) async {
    try {
      await _database.updateDog(dog.toCompanion(overrideSireId: sireId, overrideDamId: damId));
    } catch (e) {
      throw DatabaseException('Failed to update dog: $e', e);
    }
  }

  @override
  Future<void> updateDogParent(int childId, {int? sireId, bool updateSire = false, int? damId, bool updateDam = false}) async {
    try {
      final companion = DogsCompanion(
        sireId: updateSire ? Value(sireId) : const Value.absent(),
        damId: updateDam ? Value(damId) : const Value.absent(),
      );
      await (_database.update(_database.dogs)..where((d) => d.id.equals(childId))).write(companion);
    } catch (e) {
      throw DatabaseException('Failed to update dog parent: $e', e);
    }
  }

  @override
  Future<void> deleteDog(int id) async {
    try {
      final dogData = await _database.getDogById(id);
      if (dogData.photoPath != null && dogData.photoPath!.isNotEmpty) {
        await FileStorageService.deleteFile(dogData.photoPath!);
      }
      
      final gallery = await _database.getPhotosForDog(id);
      for (final photo in gallery) {
        await FileStorageService.deleteFile(photo.photoPath);
      }

      await _database.deleteDog(id);
    } catch (e) {
      throw DatabaseException('Failed to delete dog: $e', e);
    }
  }

  @override
  Future<List<domain.Dog>> getAncestorsForPedigree(int dogId, int maxGenerationDepth) async {
    final dogsData = await _database.getAncestorsForPedigree(dogId, maxGenerationDepth);
    return dogsData.map((dog) => dog.toDomain()).toList();
  }

  @override
  Future<List<domain.Dog>> getOffspringForDog(int dogId) async {
    final dogsData = await _database.getOffspringForDog(dogId);
    return dogsData.map((dog) => dog.toDomain()).toList();
  }

  @override
  Future<List<int>> getDescendantIds(int dogId) async {
    return await _database.getDescendantIds(dogId);
  }

  @override
  Future<List<domain_litter.Litter>> getLittersForDog(int dogId) async {
    final littersData = await _database.getLittersForDog(dogId);
    return littersData.map((litter) => litter.toDomain()).toList();
  }

  @override
  Future<int> createLitter(domain_litter.Litter litter) async {
    try {
      return await _database.createLitter(litter.toCompanion());
    } catch (e) {
      throw DatabaseException('Failed to create litter: $e', e);
    }
  }

  @override
  Future<int> createLitterWithPuppies(domain_litter.Litter litter, List<domain.Dog> puppies) async {
    try {
      final litterCompanion = litter.toCompanion();
      final puppyCompanions = puppies.map((p) => p.toCompanion()).toList();
      return await _database.createLitterWithPuppies(litterCompanion, puppyCompanions);
    } catch (e) {
      throw DatabaseException('Failed to create litter with puppies: $e', e);
    }
  }

  @override
  Future<domain_litter.Litter?> getLitterById(int litterId) async {
    final litterData = await _database.getLitterById(litterId);
    return litterData?.toDomain();
  }

  @override
  Future<List<domain_litter.Litter>> getAllLitters() async {
    final littersData = await _database.getAllLitters();
    return littersData.map((litter) => litter.toDomain()).toList();
  }

  @override
  Stream<List<domain_litter.Litter>> watchAllLitters() {
    return _database.watchAllLitters().map(
      (littersData) => littersData.map((litter) => litter.toDomain()).toList(),
    );
  }

  @override
  Future<List<domain.Dog>> getPuppiesInLitter(int litterId) async {
    final dogsData = await _database.getPuppiesInLitter(litterId);
    return dogsData.map((dog) => dog.toDomain()).toList();
  }

  @override
  Future<void> deleteLitter(int id) async {
    try {
      await _database.deleteLitter(id);
    } catch (e) {
      throw DatabaseException('Failed to delete litter: $e', e);
    }
  }
}
