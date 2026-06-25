class KennelProfile {
  final int id;
  final String kennelName;
  final String? breederName;
  final String? contactInfo;
  final String? phone;
  final String? whatsapp;
  final String? email;
  final String? localLogoPath;
  final String? primaryBreeds;
  final String? brandColorHex;
  final String? certificateBorderTheme;

  const KennelProfile({
    required this.id,
    required this.kennelName,
    this.breederName,
    this.contactInfo, // Legacy
    this.phone,
    this.whatsapp,
    this.email,
    this.localLogoPath,
    this.primaryBreeds,
    this.brandColorHex,
    this.certificateBorderTheme,
  });

  bool get hasCustomLogo => localLogoPath != null && localLogoPath!.isNotEmpty;
}
