import 'package:drift/drift.dart';
import '../../domain/entities/kennel_profile.dart' as domain;
import '../../../../core/database/app_database.dart';

extension KennelProfileMapper on KennelProfileData {
  domain.KennelProfile toDomain() {
    return domain.KennelProfile(
      id: id,
      kennelName: kennelName,
      breederName: breederName,
      contactInfo: contactInfo,
      phone: phone,
      whatsapp: whatsapp,
      email: email,
      localLogoPath: localLogoPath,
      primaryBreeds: primaryBreeds,
      brandColorHex: brandColorHex,
      certificateBorderTheme: certificateBorderTheme,
    );
  }
}

extension KennelProfileEntityMapper on domain.KennelProfile {
  KennelProfileCompanion toCompanion() {
    return KennelProfileCompanion(
      id: Value(id),
      kennelName: Value(kennelName),
      breederName: Value(breederName),
      contactInfo: Value(contactInfo),
      phone: Value(phone),
      whatsapp: Value(whatsapp),
      email: Value(email),
      localLogoPath: Value(localLogoPath),
      primaryBreeds: Value(primaryBreeds),
      brandColorHex: Value(brandColorHex),
      certificateBorderTheme: Value(certificateBorderTheme),
    );
  }
}
