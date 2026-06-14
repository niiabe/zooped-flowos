import '../entities/dog.dart';
import '../repositories/pedigree_repository.dart';

class InsertDogUseCase {
  final PedigreeRepository _repository;

  InsertDogUseCase(this._repository);

  Future<int> call(Dog dog) async {
    return await _repository.insertDog(dog);
  }
}
