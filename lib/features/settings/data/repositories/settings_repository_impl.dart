import '../../domain/entities/kennel_profile.dart' as domain;
import '../../domain/repositories/settings_repository.dart';
import '../../../../core/database/app_database.dart';
import '../models/kennel_profile_model.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final AppDatabase _database;

  SettingsRepositoryImpl(this._database);

  @override
  Future<domain.KennelProfile> getKennelProfile() async {
    final profileData = await _database.getKennelProfile();
    return profileData.toDomain();
  }

  @override
  Future<void> updateKennelProfile(domain.KennelProfile profile) async {
    await _database.updateKennelProfile(profile.toCompanion());
  }
}
