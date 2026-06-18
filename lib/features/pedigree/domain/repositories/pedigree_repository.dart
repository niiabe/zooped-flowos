import '../entities/dog.dart';
import '../entities/litter.dart';

abstract class PedigreeRepository {
  // Dog Data Contracts
  Future<Dog> getDogById(int id);
  Future<Dog> getDogByIdFlat(int id);
  Future<Dog> getDogByIdWithPedigree(int id);
  Future<List<Dog>> searchDogs(String query);
  Future<List<Dog>> getAllDogs();
  Future<List<Dog>> getFilteredDogs({String? sex, String? sortBy});
  Future<List<Dog>> getDogsForDropdown(String sex);
  Future<Map<int, String>> getDogNamesByIds(List<int> ids);
  Future<int> insertDog(Dog dog, {int? sireId, int? damId});
  Future<void> updateDog(Dog dog, {int? sireId, int? damId});
  Future<void> deleteDog(int id);
  Future<List<Dog>> getOffspringForDog(int dogId);
  Future<List<Litter>> getLittersForDog(int dogId);

  // Custom Pedigree Engine Contract
  Future<List<Dog>> getAncestorsForPedigree(int dogId, int maxGenerationDepth);

  // Litter Data Contracts
  Future<int> createLitter(Litter litter);
  Future<int> createLitterWithPuppies(Litter litter, List<Dog> puppies);
  Future<List<Litter>> getAllLitters();
  Future<Litter?> getLitterById(int litterId);
  Future<List<Dog>> getPuppiesInLitter(int litterId);
  Future<void> deleteLitter(int id);
}
