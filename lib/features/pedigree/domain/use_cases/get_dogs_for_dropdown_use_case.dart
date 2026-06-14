import '../entities/dog.dart';
import '../repositories/pedigree_repository.dart';

class GetDogsForDropdownUseCase {
  final PedigreeRepository _repository;

  GetDogsForDropdownUseCase(this._repository);

  Future<List<Dog>> call(String sex) async {
    return await _repository.getDogsForDropdown(sex);
  }
}
