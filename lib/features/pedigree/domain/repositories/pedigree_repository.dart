import '../entities/dog.dart';
import '../entities/litter.dart';

abstract class PedigreeRepository {
  // Dog Data Contracts
  Future<Dog> getDogById(int id);
  Future<List<Dog>> searchDogs(String query);
  Future<List<Dog>> getAllDogs();
  Future<List<Dog>> getDogsForDropdown(String sex);
  Future<int> insertDog(Dog dog);
  Future<void> updateDog(Dog dog);
  Future<void> deleteDog(int id);

  // Custom Pedigree Engine Contract
  Future<List<Dog>> getAncestorsForPedigree(int dogId, int maxGenerationDepth);

  // Litter Data Contracts
  Future<int> createLitter(Litter litter);
  Future<List<Litter>> getAllLitters();
  Future<Litter?> getLitterById(int litterId);
  Future<List<Dog>> getPuppiesInLitter(int litterId);
  Future<void> deleteLitter(int id);
}
