import '../../domain/entities/dog.dart' as domain;
import '../../domain/entities/litter.dart' as domain_litter;
import '../../domain/repositories/pedigree_repository.dart';
import '../../../../core/database/app_database.dart';
import '../models/dog_model.dart';
import '../models/litter_model.dart';

class PedigreeRepositoryImpl implements PedigreeRepository {
  final AppDatabase _database;

  PedigreeRepositoryImpl(this._database);

  @override
  Future<domain.Dog> getDogById(int id) async {
    final dogData = await _database.getDogById(id);
    final sire = await _hydrate(dogData.sireId);
    final dam = await _hydrate(dogData.damId);
    return dogData.toDomain(sire: sire, dam: dam);
  }

  Future<domain.Dog?> _hydrate(int? id, {int depth = 0}) async {
    if (id == null || depth > 6) return null;
    final data = await _database.getSireOrDam(id);
    if (data == null) return null;
    final sire = await _hydrate(data.sireId, depth: depth + 1);
    final dam = await _hydrate(data.damId, depth: depth + 1);
    return data.toDomain(sire: sire, dam: dam);
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
  Future<int> insertDog(domain.Dog dog) async {
    return await _database.insertDog(dog.toCompanion());
  }

  @override
  Future<void> updateDog(domain.Dog dog) async {
    await _database.updateDog(dog.toCompanion());
  }

  @override
  Future<void> deleteDog(int id) async {
    await _database.deleteDog(id);
  }

  @override
  Future<List<domain.Dog>> getAncestorsForPedigree(int dogId, int maxGenerationDepth) async {
    final dogsData = await _database.getAncestorsForPedigree(dogId, maxGenerationDepth);
    return dogsData.map((dog) => dog.toDomain()).toList();
  }

  @override
  Future<int> createLitter(domain_litter.Litter litter) async {
    return await _database.createLitter(litter.toCompanion());
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
  Future<List<domain.Dog>> getPuppiesInLitter(int litterId) async {
    final dogsData = await _database.getPuppiesInLitter(litterId);
    return dogsData.map((dog) => dog.toDomain()).toList();
  }

  @override
  Future<void> deleteLitter(int id) async {
    await _database.deleteLitter(id);
  }
}
