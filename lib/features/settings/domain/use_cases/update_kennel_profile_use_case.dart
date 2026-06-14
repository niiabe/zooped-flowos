import '../entities/kennel_profile.dart';
import '../repositories/settings_repository.dart';

class UpdateKennelProfileUseCase {
  final SettingsRepository _repository;

  UpdateKennelProfileUseCase(this._repository);

  Future<void> call(KennelProfile profile) async {
    await _repository.updateKennelProfile(profile);
  }
}
