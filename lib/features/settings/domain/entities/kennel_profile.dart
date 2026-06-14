class KennelProfile {
  final int id;
  final String kennelName;
  final String? breederName;
  final String? contactInfo;
  final String? localLogoPath;

  const KennelProfile({
    required this.id,
    required this.kennelName,
    this.breederName,
    this.contactInfo,
    this.localLogoPath,
  });

  bool get hasCustomLogo => localLogoPath != null && localLogoPath!.isNotEmpty;
}
