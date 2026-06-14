import '../entities/dog.dart';
import '../repositories/pedigree_repository.dart';

class GetAncestorsUseCase {
  final PedigreeRepository _repository;

  GetAncestorsUseCase(this._repository);

  Future<List<Dog>> call(int dogId, {int maxGenerationDepth = 3}) async {
    return await _repository.getAncestorsForPedigree(dogId, maxGenerationDepth);
  }
}
