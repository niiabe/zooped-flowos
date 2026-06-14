import '../entities/kennel_profile.dart';

abstract class SettingsRepository {
  Future<KennelProfile> getKennelProfile();
  Future<void> updateKennelProfile(KennelProfile profile);
}
