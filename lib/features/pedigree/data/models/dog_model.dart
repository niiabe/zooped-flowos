import 'package:drift/drift.dart';
import '../../domain/entities/dog.dart' as domain;
import '../../../../core/database/app_database.dart';

extension DogMapper on Dog {
  domain.Dog toDomain({
    domain.Dog? sire,
    domain.Dog? dam,
  }) {
    return domain.Dog(
      id: id,
      registeredName: registeredName,
      callName: callName,
      sex: sex,
      dateOfBirth: dateOfBirth,
      microchipNumber: microchipNumber,
      colorMarkings: colorMarkings,
      sire: sire,
      dam: dam,
      litterId: litterId,
      appraisalScore: appraisalScore,
      inbreedingCoefficient: inbreedingCoefficient,
      registerType: registerType,
      dnaProfileNumber: dnaProfileNumber,
      notes: notes,
      createdAt: createdAt,
    );
  }
}

extension DogEntityMapper on domain.Dog {
  DogsCompanion toCompanion() {
    return DogsCompanion(
      id: Value(id),
      registeredName: Value(registeredName),
      callName: Value(callName),
      sex: Value(sex),
      dateOfBirth: Value(dateOfBirth),
      microchipNumber: Value(microchipNumber),
      colorMarkings: Value(colorMarkings),
      sireId: Value(sire?.id),
      damId: Value(dam?.id),
      litterId: Value(litterId),
      appraisalScore: Value(appraisalScore),
      inbreedingCoefficient: Value(inbreedingCoefficient),
      registerType: Value(registerType),
      dnaProfileNumber: Value(dnaProfileNumber),
      notes: Value(notes),
    );
  }
}
