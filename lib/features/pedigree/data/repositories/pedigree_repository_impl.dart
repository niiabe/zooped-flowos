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
      final sanitized = dog.copyWith(
        registeredName: dog.registeredName.trim(),
        callName: dog.callName.trim(),
        breed: dog.breed?.trim(),
        colorMarkings: dog.colorMarkings?.trim(),
        microchipNumber: dog.microchipNumber?.trim(),
        registerType: dog.registerType?.trim(),
        dnaProfileNumber: dog.dnaProfileNumber?.trim(),
        notes: dog.notes?.trim(),
      );
      return await _database.insertDog(sanitized.toCompanion(overrideSireId: sireId, overrideDamId: damId));
    } catch (e) {
      throw DatabaseException('Failed to insert dog: $e', e);
    }
  }

  @override
  Future<void> updateDog(domain.Dog dog, {int? sireId, int? damId}) async {
    try {
      final sanitized = dog.copyWith(
        registeredName: dog.registeredName.trim(),
        callName: dog.callName.trim(),
        breed: dog.breed?.trim(),
        colorMarkings: dog.colorMarkings?.trim(),
        microchipNumber: dog.microchipNumber?.trim(),
        registerType: dog.registerType?.trim(),
        dnaProfileNumber: dog.dnaProfileNumber?.trim(),
        notes: dog.notes?.trim(),
      );
      await _database.updateDog(sanitized.toCompanion(overrideSireId: sireId, overrideDamId: damId));
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

  @override
  Future<void> updateLitterWithPuppies(domain_litter.Litter litter, List<domain.Dog> puppies) async {
    try {
      final dbPuppies = puppies.map((p) => p.toCompanion()).toList();
      await _database.updateLitterWithPuppies(litter.toCompanion(), dbPuppies);
    } catch (e) {
      throw DatabaseException('Failed to update litter: $e', e);
    }
  }

  @override
  Future<void> deleteShowRecord(int id) async {
    try {
      await (_database.delete(_database.showRecords)..where((s) => s.id.equals(id))).go();
    } catch (e) {
      throw DatabaseException('Failed to delete show record: $e', e);
    }
  }

  @override
  Future<void> addDogPhoto(int dogId, String photoPath) async {
    try {
      await _database.into(_database.dogPhotos).insert(
        DogPhotosCompanion.insert(dogId: dogId, photoPath: photoPath),
      );
    } catch (e) {
      throw DatabaseException('Failed to add dog photo: $e', e);
    }
  }

  @override
  Future<void> deleteDogPhoto(int id) async {
    try {
      await (_database.delete(_database.dogPhotos)..where((p) => p.id.equals(id))).go();
    } catch (e) {
      throw DatabaseException('Failed to delete dog photo: $e', e);
    }
  }

  @override
  Future<void> addHeatCycle(int dogId, DateTime startDate) async {
    try {
      await _database.into(_database.heatCycles).insert(
        HeatCyclesCompanion.insert(dogId: dogId, startDate: startDate),
      );
    } catch (e) {
      throw DatabaseException('Failed to add heat cycle: $e', e);
    }
  }

  @override
  Future<void> deleteHeatCycle(int id) async {
    try {
      await (_database.delete(_database.heatCycles)..where((h) => h.id.equals(id))).go();
    } catch (e) {
      throw DatabaseException('Failed to delete heat cycle: $e', e);
    }
  }

  @override
  Future<int> getTotalDogCount() async {
    try {
      final count = _database.dogs.id.count();
      final query = _database.selectOnly(_database.dogs)..addColumns([count]);
      final result = await query.getSingle();
      return result.read(count) ?? 0;
    } catch (e) {
      throw DatabaseException('Failed to get dog count: $e', e);
    }
  }

  @override
  Future<int> getTotalLitterCount() async {
    try {
      final count = _database.litters.id.count();
      final query = _database.selectOnly(_database.litters)..addColumns([count]);
      final result = await query.getSingle();
      return result.read(count) ?? 0;
    } catch (e) {
      throw DatabaseException('Failed to get litter count: $e', e);
    }
  }

  @override
  Future<List<domain.Dog>> getAllDogsForAnalytics() async {
    try {
      final dogsData = await _database.getAllDogs();
      return dogsData.map((dog) => dog.toDomain()).toList();
    } catch (e) {
      throw DatabaseException('Failed to get dogs for analytics: $e', e);
    }
  }

  @override
  Future<int> addHealthRecord(HealthRecordsCompanion record) async {
    try {
      return await _database.into(_database.healthRecords).insert(record);
    } catch (e) {
      throw DatabaseException('Failed to add health record: $e', e);
    }
  }

  @override
  Future<List<HealthRecord>> getDogHealthRecords(int dogId) async {
    try {
      return await (_database.select(_database.healthRecords)
            ..where((h) => h.dogId.equals(dogId))
            ..orderBy([(h) => OrderingTerm(expression: h.date, mode: OrderingMode.desc)]))
          .get();
    } catch (e) {
      throw DatabaseException('Failed to get health records: $e', e);
    }
  }

  @override
  Future<void> deleteHealthRecord(int id) async {
    try {
      await (_database.delete(_database.healthRecords)..where((h) => h.id.equals(id))).go();
    } catch (e) {
      throw DatabaseException('Failed to delete health record: $e', e);
    }
  }

  @override
  Future<void> updateHealthRecord(HealthRecord record) async {
    try {
      await _database.update(_database.healthRecords).replace(record);
    } catch (e) {
      throw DatabaseException('Failed to update health record: $e', e);
    }
  }

  @override
  Future<void> addLitterHealthRecord(LitterHealthRecordsCompanion record) async {
    try {
      await _database.into(_database.litterHealthRecords).insert(record);
    } catch (e) {
      throw DatabaseException('Failed to add litter health record: $e', e);
    }
  }

  @override
  Future<List<LitterHealthRecord>> getLitterHealthRecords(int litterId) async {
    try {
      return await (_database.select(_database.litterHealthRecords)
            ..where((l) => l.litterId.equals(litterId))
            ..orderBy([(l) => OrderingTerm(expression: l.date, mode: OrderingMode.desc)]))
          .get();
    } catch (e) {
      throw DatabaseException('Failed to get litter health records: $e', e);
    }
  }

  @override
  Future<void> deleteLitterHealthRecord(int id) async {
    try {
      await (_database.delete(_database.litterHealthRecords)..where((l) => l.id.equals(id))).go();
    } catch (e) {
      throw DatabaseException('Failed to delete litter health record: $e', e);
    }
  }

  @override
  Future<List<HealthRecord>> getHealthRecordsForLitterPuppies(int litterId) async {
    try {
      return await _database.getHealthRecordsForLitterPuppies(litterId);
    } catch (e) {
      throw DatabaseException('Failed to get health records for litter puppies: $e', e);
    }
  }

  @override
  Future<void> addHealthRecordForLitterPuppies(int litterId, String recordType, DateTime date, {DateTime? nextDueDate, String? notes}) async {
    try {
      final record = HealthRecordsCompanion.insert(
        dogId: 0, // placeholder, will be overridden per puppy
        recordType: recordType,
        date: date,
        nextDueDate: nextDueDate != null ? Value(nextDueDate) : const Value.absent(),
        notes: notes != null ? Value(notes) : const Value.absent(),
      );
      await _database.addHealthRecordForLitterPuppies(litterId, record);
    } catch (e) {
      throw DatabaseException('Failed to add health records for litter puppies: $e', e);
    }
  }

  @override
  Future<void> copyHealthRecordsFromLitterToDog(int litterId, int newDogId) async {
    try {
      await _database.copyHealthRecordsFromLitterToDog(litterId, newDogId);
    } catch (e) {
      throw DatabaseException('Failed to copy health records from litter: $e', e);
    }
  }
}
