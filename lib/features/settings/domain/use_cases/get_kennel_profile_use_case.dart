import '../entities/kennel_profile.dart';
import '../repositories/settings_repository.dart';

class GetKennelProfileUseCase {
  final SettingsRepository _repository;

  GetKennelProfileUseCase(this._repository);

  Future<KennelProfile> call() async {
    return await _repository.getKennelProfile();
  }
}
