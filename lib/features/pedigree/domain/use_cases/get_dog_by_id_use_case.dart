import '../entities/dog.dart';
import '../repositories/pedigree_repository.dart';

class GetDogByIdUseCase {
  final PedigreeRepository _repository;

  GetDogByIdUseCase(this._repository);

  Future<Dog> call(int id) async {
    return await _repository.getDogById(id);
  }
}
