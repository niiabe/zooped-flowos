import '../repositories/pedigree_repository.dart';

class DeleteLitterUseCase {
  final PedigreeRepository _repository;

  DeleteLitterUseCase(this._repository);

  Future<void> call(int id) async {
    await _repository.deleteLitter(id);
  }
}
