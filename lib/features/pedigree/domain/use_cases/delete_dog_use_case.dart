import '../repositories/pedigree_repository.dart';

class DeleteDogUseCase {
  final PedigreeRepository _repository;

  DeleteDogUseCase(this._repository);

  Future<void> call(int id) async {
    await _repository.deleteDog(id);
  }
}
