import '../entities/litter.dart';
import '../repositories/pedigree_repository.dart';

class CreateLitterUseCase {
  final PedigreeRepository _repository;

  CreateLitterUseCase(this._repository);

  Future<int> call(Litter litter) async {
    return await _repository.createLitter(litter);
  }
}
