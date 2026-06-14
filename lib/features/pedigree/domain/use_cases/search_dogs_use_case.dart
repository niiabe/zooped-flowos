import '../entities/dog.dart';
import '../repositories/pedigree_repository.dart';

class SearchDogsUseCase {
  final PedigreeRepository _repository;

  SearchDogsUseCase(this._repository);

  Future<List<Dog>> call(String query) async {
    return await _repository.searchDogs(query);
  }
}
