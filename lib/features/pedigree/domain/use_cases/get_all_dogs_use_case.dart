import '../entities/dog.dart';
import '../repositories/pedigree_repository.dart';

class GetAllDogsUseCase {
  final PedigreeRepository _repository;

  GetAllDogsUseCase(this._repository);

  Future<List<Dog>> call() async {
    return await _repository.getAllDogs();
  }
}
