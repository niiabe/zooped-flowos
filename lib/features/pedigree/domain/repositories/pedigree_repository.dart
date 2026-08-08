import '../entities/dog.dart';
import '../entities/litter.dart';
import '../../../../core/database/app_database.dart' show HealthRecordsCompanion, LitterHealthRecordsCompanion, HealthRecord, LitterHealthRecord, Mating, ShowRecord;

abstract class PedigreeRepository {
  // Dog Data Contracts
  Future<Dog> getDogById(int id);
  Future<Dog> getDogByIdFlat(int id);
  Future<Dog> getDogByIdWithPedigree(int id);
  Future<List<Dog>> searchDogs(String query);
  Future<List<Dog>> getAllDogs();
  Future<List<Dog>> getFilteredDogs({String? sex, String? sortBy});
  Stream<List<Dog>> watchFilteredDogs({String? sex, String? sortBy});
  Future<List<Dog>> getDogsForDropdown(String sex);
  Future<Map<int, String>> getDogNamesByIds(List<int> ids);
  Future<int> insertDog(Dog dog, {int? sireId, int? damId});
  Future<void> updateDog(Dog dog, {int? sireId, int? damId});
  Future<void> updateDogParent(int childId, {int? sireId, bool updateSire = false, int? damId, bool updateDam = false});
  Future<void> deleteDog(int id);
  Future<List<Dog>> getOffspringForDog(int dogId);
  Future<List<int>> getDescendantIds(int dogId);
  Future<List<Litter>> getLittersForDog(int dogId);

  // Custom Pedigree Engine Contract
  Future<List<Dog>> getAncestorsForPedigree(int dogId, int maxGenerationDepth);

  Future<int> createLitter(Litter litter);
  Future<int> createLitterWithPuppies(Litter litter, List<Dog> puppies);
  Future<void> updateLitterWithPuppies(Litter litter, List<Dog> puppies);
  Future<Litter?> getLitterById(int litterId);
  Future<List<Litter>> getAllLitters();
  Stream<List<Litter>> watchAllLitters();
  Future<List<Dog>> getPuppiesInLitter(int litterId);
  Future<void> deleteLitter(int id);

  Future<int> addHealthRecord(HealthRecordsCompanion record);
  Future<List<HealthRecord>> getDogHealthRecords(int dogId);
  Future<void> deleteHealthRecord(int id);
  Future<void> updateHealthRecord(HealthRecord record);

  // Show Records
  Future<List<ShowRecord>> getDogShowRecords(int dogId);
  Future<void> deleteShowRecord(int id);

  // Photo Gallery
  Future<void> addDogPhoto(int dogId, String photoPath);
  Future<void> deleteDogPhoto(int id);

  // Heat Cycles
  Future<void> addHeatCycle(int dogId, DateTime startDate);
  Future<void> deleteHeatCycle(int id);

  // Analytics
  Future<int> getTotalDogCount();
  Future<int> getTotalLitterCount();
  Future<List<Dog>> getAllDogsForAnalytics();

  // Litter Health Records
  Future<void> addLitterHealthRecord(LitterHealthRecordsCompanion record);
  Future<List<LitterHealthRecord>> getLitterHealthRecords(int litterId);
  Future<void> deleteLitterHealthRecord(int id);

  // Litter Health Record Contracts
  Future<List<HealthRecord>> getHealthRecordsForLitterPuppies(int litterId);
  Future<void> addHealthRecordForLitterPuppies(int litterId, String recordType, DateTime date, {DateTime? nextDueDate, String? notes});
  Future<void> copyHealthRecordsFromLitterToDog(int litterId, int newDogId);

  // Matings
  Future<List<Mating>> getMatingsForDog(int dogId);
  Future<void> addMating(int sireId, int damId, DateTime matingDate, {String? notes});
  Future<void> deleteMating(int id);
}
