import '../entities/dog.dart';
import '../repositories/pedigree_repository.dart';

class UpdateDogUseCase {
  final PedigreeRepository _repository;

  UpdateDogUseCase(this._repository);

  Future<void> call(Dog dog) async {
    await _repository.updateDog(dog);
  }
}
