class Dog {
  final int id;
  final String registeredName;
  final String callName;
  final String? breed;
  final String sex; // 'Male' or 'Female'
  final DateTime? dateOfBirth;
  final String? microchipNumber;
  final String? colorMarkings;
  
  // Clean Architecture Entity Associations
  final Dog? sire;
  final Dog? dam;
  final int? litterId;

  // Official Evaluation & Certificate Metrics
  final double? appraisalScore;
  final double? inbreedingCoefficient;
  final String? registerType; // 'SP', 'SR', 'B'
  final String? dnaProfileNumber;
  final String? photoPath;

  final String? saleStatus;
  final String? notes;
  final DateTime createdAt;

  const Dog({
    required this.id,
    required this.registeredName,
    required this.callName,
    this.breed,
    required this.sex,
    this.dateOfBirth,
    this.microchipNumber,
    this.colorMarkings,
    this.sire,
    this.dam,
    this.litterId,
    this.appraisalScore,
    this.inbreedingCoefficient,
    this.registerType,
    this.dnaProfileNumber,
    this.photoPath,
    this.saleStatus,
    this.notes,
    required this.createdAt,
  });

  bool get isFoundationDog => sire == null && dam == null;

  Dog copyWith({
    int? id,
    String? registeredName,
    String? callName,
    String? breed,
    String? sex,
    DateTime? dateOfBirth,
    String? microchipNumber,
    String? colorMarkings,
    Dog? sire,
    bool clearSire = false,
    Dog? dam,
    bool clearDam = false,
    int? litterId,
    bool clearLitterId = false,
    double? appraisalScore,
    double? inbreedingCoefficient,
    String? registerType,
    String? dnaProfileNumber,
    String? photoPath,
    String? saleStatus,
    String? notes,
    DateTime? createdAt,
  }) {
    return Dog(
      id: id ?? this.id,
      registeredName: registeredName ?? this.registeredName,
      callName: callName ?? this.callName,
      breed: breed ?? this.breed,
      sex: sex ?? this.sex,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      microchipNumber: microchipNumber ?? this.microchipNumber,
      colorMarkings: colorMarkings ?? this.colorMarkings,
      sire: clearSire ? null : (sire ?? this.sire),
      dam: clearDam ? null : (dam ?? this.dam),
      litterId: clearLitterId ? null : (litterId ?? this.litterId),
      appraisalScore: appraisalScore ?? this.appraisalScore,
      inbreedingCoefficient: inbreedingCoefficient ?? this.inbreedingCoefficient,
      registerType: registerType ?? this.registerType,
      dnaProfileNumber: dnaProfileNumber ?? this.dnaProfileNumber,
      photoPath: photoPath ?? this.photoPath,
      saleStatus: saleStatus ?? this.saleStatus,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
