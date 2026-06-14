import 'package:drift/drift.dart';
import '../../domain/entities/litter.dart' as domain;
import '../../../../core/database/app_database.dart';

extension LitterMapper on Litter {
  domain.Litter toDomain() {
    return domain.Litter(
      id: id,
      sireId: sireId,
      damId: damId,
      matingDate: matingDate,
      whelpingDate: whelpingDate,
      puppiesBornAlive: puppiesBornAlive,
      puppiesStillborn: puppiesStillborn,
      notes: notes,
    );
  }
}

extension LitterEntityMapper on domain.Litter {
  LittersCompanion toCompanion() {
    return LittersCompanion(
      id: Value(id),
      sireId: Value(sireId),
      damId: Value(damId),
      matingDate: Value(matingDate),
      whelpingDate: Value(whelpingDate),
      puppiesBornAlive: Value(puppiesBornAlive),
      puppiesStillborn: Value(puppiesStillborn),
      notes: Value(notes),
    );
  }
}
