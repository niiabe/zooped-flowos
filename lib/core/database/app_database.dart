import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

class KennelProfile extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get kennelName => text().withLength(min: 1, max: 100)();
  TextColumn get breederName => text().nullable()();
  TextColumn get contactInfo => text().nullable()(); // legacy
  TextColumn get phone => text().nullable()();
  TextColumn get whatsapp => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get localLogoPath => text().nullable()();
  TextColumn get primaryBreeds => text().nullable()();
  TextColumn get brandColorHex => text().nullable()();
  TextColumn get certificateBorderTheme => text().nullable()();
  TextColumn get customSignaturePath => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Dogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get registeredName => text().withLength(min: 1, max: 150).unique()();
  TextColumn get callName => text().withLength(min: 1, max: 50)();
  TextColumn get breed => text().nullable()();
  TextColumn get sex => text().withLength(min: 1, max: 10)(); // 'Male' or 'Female'
  DateTimeColumn get dateOfBirth => dateTime().nullable()();
  TextColumn get microchipNumber => text().nullable().unique()();
  TextColumn get colorMarkings => text().nullable()();
  
  // Self-referencing foreign keys for lineage
  @ReferenceName('siredDogs')
  IntColumn get sireId => integer().references(Dogs, #id).nullable()();
  @ReferenceName('damDogs')
  IntColumn get damId => integer().references(Dogs, #id).nullable()();
  IntColumn get litterId => integer().nullable()(); // No foreign key to avoid circular reference
  
  // Certificate metrics
  RealColumn get appraisalScore => real().nullable()();
  RealColumn get inbreedingCoefficient => real().nullable()();
  TextColumn get registerType => text().nullable()(); // 'SP', 'SR', 'B'
  TextColumn get dnaProfileNumber => text().nullable()();
  TextColumn get saleStatus => text().nullable()(); // 'Available', 'Reserved', 'Sold'
  
  TextColumn get photoPath => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Litters extends Table {
  IntColumn get id => integer().autoIncrement()();
  @ReferenceName('siredLitters')
  IntColumn get sireId => integer().references(Dogs, #id).nullable()();
  @ReferenceName('damLitters')
  IntColumn get damId => integer().references(Dogs, #id).nullable()();
  DateTimeColumn get matingDate => dateTime().nullable()();
  DateTimeColumn get whelpingDate => dateTime()();
  IntColumn get puppiesBornAlive => integer().withDefault(const Constant(0))();
  IntColumn get puppiesStillborn => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
}

class DogPhotos extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dogId => integer().references(Dogs, #id)();
  TextColumn get photoPath => text()();
  TextColumn get caption => text().nullable()();
  DateTimeColumn get dateAdded => dateTime().withDefault(currentDateAndTime)();
}

class HealthRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dogId => integer().references(Dogs, #id)();
  TextColumn get recordType => text().withLength(min: 1, max: 50)(); // 'Vaccine', 'Deworming', 'Vet', 'Heat'
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get nextDueDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class ShowRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dogId => integer().references(Dogs, #id)();
  TextColumn get eventName => text().withLength(min: 1, max: 100)();
  DateTimeColumn get date => dateTime()();
  TextColumn get judge => text().nullable()();
  TextColumn get placement => text().nullable()();
  TextColumn get titleAwarded => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get transactionType => text().withLength(min: 1, max: 20)(); // 'Expense', 'Revenue'
  TextColumn get category => text().withLength(min: 1, max: 50)();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class HeatCycles extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dogId => integer().references(Dogs, #id)();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
}

class Matings extends Table {
  IntColumn get id => integer().autoIncrement()();
  @ReferenceName('matingSires')
  IntColumn get sireId => integer().references(Dogs, #id)();
  @ReferenceName('matingDams')
  IntColumn get damId => integer().references(Dogs, #id)();
  DateTimeColumn get matingDate => dateTime()();
  TextColumn get notes => text().nullable()();
}


@DriftDatabase(
  tables: [KennelProfile, Dogs, Litters, DogPhotos, HealthRecords, ShowRecords, Transactions, HeatCycles, Matings],
  daos: [],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await into(kennelProfile).insert(
          KennelProfileCompanion.insert(
            kennelName: 'My Kennel',
          ),
        );
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(dogs, dogs.photoPath);
        }
        if (from < 3) {
          await m.createTable(dogPhotos);
        }
        if (from < 4) {
          await m.createTable(healthRecords);
        }
        if (from < 5) {
          await m.createTable(showRecords);
        }
        if (from < 6) {
          await m.addColumn(kennelProfile, kennelProfile.phone);
          await m.addColumn(kennelProfile, kennelProfile.whatsapp);
          await m.addColumn(kennelProfile, kennelProfile.email);
        }
        if (from < 7) {
          await customStatement('PRAGMA foreign_keys = OFF');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_dogs_sire_id ON dogs(sire_id)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_dogs_dam_id ON dogs(dam_id)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_dogs_litter_id ON dogs(litter_id)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_dogs_sex ON dogs(sex)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_litters_sire_id ON litters(sire_id)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_litters_dam_id ON litters(dam_id)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_dog_photos_dog_id ON dog_photos(dog_id)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_health_records_dog_id ON health_records(dog_id)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_show_records_dog_id ON show_records(dog_id)');
          await customStatement('PRAGMA foreign_keys = ON');
        }
        if (from < 8) {
          await m.addColumn(dogs, dogs.saleStatus);
          await m.createTable(transactions);
          await m.createTable(heatCycles);
          await m.createTable(matings);
        }
        if (from < 9) {
          await customStatement('CREATE INDEX IF NOT EXISTS idx_dogs_call_name ON dogs(call_name)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_dogs_registered_name ON dogs(registered_name)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_dogs_microchip ON dogs(microchip_number)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_heat_cycles_dog_id ON heat_cycles(dog_id)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_matings_sire_id ON matings(sire_id)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_matings_dam_id ON matings(dam_id)');
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
        if (details.wasCreated) {
          await _createIndexes();
        }
      },
    );
  }

  Future<void> _createIndexes() async {
    await customStatement('CREATE INDEX IF NOT EXISTS idx_dogs_sire_id ON dogs(sire_id)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_dogs_dam_id ON dogs(dam_id)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_dogs_litter_id ON dogs(litter_id)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_dogs_sex ON dogs(sex)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_litters_sire_id ON litters(sire_id)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_litters_dam_id ON litters(dam_id)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_dog_photos_dog_id ON dog_photos(dog_id)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_health_records_dog_id ON health_records(dog_id)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_show_records_dog_id ON show_records(dog_id)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_dogs_call_name ON dogs(call_name)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_dogs_registered_name ON dogs(registered_name)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_dogs_microchip ON dogs(microchip_number)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_heat_cycles_dog_id ON heat_cycles(dog_id)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_matings_sire_id ON matings(sire_id)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_matings_dam_id ON matings(dam_id)');
  }

  // Kennel Profile Operations
  Future<KennelProfileData> getKennelProfile() async {
    final profiles = await (select(kennelProfile)..limit(1)).get();
    if (profiles.isNotEmpty) return profiles.first;
    final id = await into(kennelProfile).insert(
      KennelProfileCompanion.insert(kennelName: 'My Kennel'),
    );
    return await (select(kennelProfile)..where((p) => p.id.equals(id))).getSingle();
  }

  Future<void> updateKennelProfile(KennelProfileCompanion profile) async {
    await update(kennelProfile).replace(profile);
  }

  // Dog Operations
  Future<List<Dog>> searchDogs(String query) async {
    final lowerQuery = '%${query.toLowerCase()}%';
    return await (select(dogs)
      ..where((d) => 
        d.callName.like(lowerQuery) | 
        d.registeredName.like(lowerQuery) |
        d.microchipNumber.like(lowerQuery)
      ))
      .get();
  }

  Future<Dog> getDogById(int id) async {
    return await (select(dogs)..where((d) => d.id.equals(id))).getSingle();
  }

  Future<List<Dog>> getDogsByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    return await (select(dogs)..where((d) => d.id.isIn(ids))).get();
  }

  Future<Dog?> getDogByIdOrNull(int id) async {
    return await (select(dogs)..where((d) => d.id.equals(id))).getSingleOrNull();
  }

  Future<Dog?> getSireOrDam(int? id) async {
    if (id == null) return null;
    return await (select(dogs)..where((d) => d.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertDog(DogsCompanion dog) async {
    return await into(dogs).insert(dog);
  }

  Future<void> updateDog(DogsCompanion dog) async {
    await update(dogs).replace(dog);
  }

  Future<void> deleteDog(int id) async {
    await transaction(() async {
      await (delete(dogPhotos)..where((p) => p.dogId.equals(id))).go();
      await (update(dogs)..where((d) => d.sireId.equals(id))).write(const DogsCompanion(sireId: Value(null)));
      await (update(dogs)..where((d) => d.damId.equals(id))).write(const DogsCompanion(damId: Value(null)));
      await (update(litters)..where((l) => l.sireId.equals(id))).write(const LittersCompanion(sireId: Value(null)));
      await (update(litters)..where((l) => l.damId.equals(id))).write(const LittersCompanion(damId: Value(null)));
      await (delete(dogs)..where((d) => d.id.equals(id))).go();
    });
  }

  Future<List<Dog>> getDogsForDropdown(String sex) async {
    return await (select(dogs)..where((d) => d.sex.equals(sex))
      ..orderBy([(d) => OrderingTerm.asc(d.callName)]))
      .get();
  }

  Future<List<Dog>> getAncestorsForPedigree(int dogId, int maxDepth) async {
    final Map<int, Dog> dogMap = {};
    final List<int> currentIds = [dogId];

    int currentDepth = 0;
    while (currentDepth < maxDepth && currentIds.isNotEmpty) {
      final batchIds = List<int>.from(currentIds);
      currentIds.clear();

      final batchResults = await (select(dogs)..where((d) => d.id.isIn(batchIds))).get();
      for (final dog in batchResults) {
        dogMap[dog.id] = dog;
      }

      for (final id in batchIds) {
        final dog = dogMap[id];
        if (dog == null) continue;
        if (dog.sireId != null && !dogMap.containsKey(dog.sireId)) {
          currentIds.add(dog.sireId!);
        }
        if (dog.damId != null && !dogMap.containsKey(dog.damId)) {
          currentIds.add(dog.damId!);
        }
      }

      currentDepth++;
    }

    return dogMap.values.toList()..sort((a, b) => a.id.compareTo(b.id));
  }

  // Photo Gallery Operations
  Future<int> addDogPhoto(DogPhotosCompanion photo) async {
    return await into(dogPhotos).insert(photo);
  }

  Future<void> deleteDogPhoto(int id) async {
    await (delete(dogPhotos)..where((p) => p.id.equals(id))).go();
  }

  Future<List<DogPhoto>> getPhotosForDog(int dogId) async {
    return await (select(dogPhotos)..where((p) => p.dogId.equals(dogId))
      ..orderBy([(p) => OrderingTerm.desc(p.dateAdded)])).get();
  }

  // Health Record Operations
  Future<int> addHealthRecord(HealthRecordsCompanion record) async {
    return await into(healthRecords).insert(record);
  }

  Future<void> deleteHealthRecord(int id) async {
    await (delete(healthRecords)..where((r) => r.id.equals(id))).go();
  }

  Future<List<HealthRecord>> getHealthRecordsForDog(int dogId) async {
    return await (select(healthRecords)..where((r) => r.dogId.equals(dogId))
      ..orderBy([(r) => OrderingTerm.desc(r.date)])).get();
  }

  // Show Record Operations
  Future<int> addShowRecord(ShowRecordsCompanion record) async {
    return await into(showRecords).insert(record);
  }

  Future<void> deleteShowRecord(int id) =>
      (delete(showRecords)..where((t) => t.id.equals(id))).go();

  // Transactions
  Future<List<Transaction>> getAllTransactions() => select(transactions).get();
  Stream<List<Transaction>> watchTransactions() => select(transactions).watch();
  Future<int> addTransaction(TransactionsCompanion entry) => into(transactions).insert(entry);
  Future<void> deleteTransaction(int id) => (delete(transactions)..where((t) => t.id.equals(id))).go();

  // Heat Cycles
  Stream<List<HeatCycle>> watchHeatCycles(int dogId) =>
      (select(heatCycles)..where((t) => t.dogId.equals(dogId))).watch();
  Future<int> addHeatCycle(HeatCyclesCompanion entry) => into(heatCycles).insert(entry);
  Future<void> deleteHeatCycle(int id) => (delete(heatCycles)..where((t) => t.id.equals(id))).go();

  // Matings
  Stream<List<Mating>> watchMatings(int dogId) =>
      (select(matings)..where((t) => t.sireId.equals(dogId) | t.damId.equals(dogId))).watch();
  Stream<List<Mating>> watchUpcomingWhelpings() {
    final cutoff = DateTime.now().subtract(const Duration(days: 64));
    return (select(matings)..where((t) => t.matingDate.isBiggerOrEqualValue(cutoff))
                           ..orderBy([(t) => OrderingTerm(expression: t.matingDate, mode: OrderingMode.asc)]))
        .watch();
  }
  Future<int> addMating(MatingsCompanion entry) => into(matings).insert(entry);
  Future<void> deleteMating(int id) => (delete(matings)..where((t) => t.id.equals(id))).go();

  Future<List<ShowRecord>> getShowRecordsForDog(int dogId) async {
    return await (select(showRecords)..where((r) => r.dogId.equals(dogId))
      ..orderBy([(r) => OrderingTerm.desc(r.date)])).get();
  }

  // Litter Operations
  Future<int> createLitter(LittersCompanion litter) async {
    return await into(litters).insert(litter);
  }

  Future<Litter?> getLitterById(int litterId) async {
    return await (select(litters)..where((l) => l.id.equals(litterId))).getSingleOrNull();
  }

  Future<List<Dog>> getPuppiesInLitter(int litterId) async {
    return await (select(dogs)..where((d) => d.litterId.equals(litterId))).get();
  }

  Future<void> deleteLitter(int id) async {
    await transaction(() async {
      await (update(dogs)..where((d) => d.litterId.equals(id))).write(const DogsCompanion(litterId: Value(null)));
      await (delete(litters)..where((l) => l.id.equals(id))).go();
    });
  }

  Future<List<Litter>> getLittersForDog(int dogId) async {
    return await (select(litters)..where((l) => l.sireId.equals(dogId) | l.damId.equals(dogId))).get();
  }

  Future<List<Dog>> getOffspringForDog(int dogId) async {
    return await (select(dogs)..where((d) => d.sireId.equals(dogId) | d.damId.equals(dogId))).get();
  }

  Future<List<Dog>> getAllDogs() async {
    return await select(dogs).get();
  }

  Future<List<Dog>> getFilteredDogs({String? sex, String? sortBy}) async {
    var query = select(dogs);
    if (sex != null && sex != 'All') {
      query = query..where((d) => d.sex.equals(sex));
    }
    if (sortBy == 'Name (A-Z)') {
      query = query..orderBy([(d) => OrderingTerm.asc(d.callName)]);
    } else if (sortBy == 'Recent') {
      query = query..orderBy([(d) => OrderingTerm.desc(d.id)]);
    } else if (sortBy == 'Age (Youngest)') {
      query = query..orderBy([(d) => OrderingTerm.desc(d.dateOfBirth)]);
    }
    return await query.get();
  }

  Future<List<Litter>> getAllLitters() async {
    return await select(litters).get();
  }

  Future<void> bulkInsertDogs(List<DogsCompanion> dogsList) async {
    await batch((batch) {
      batch.insertAll(dogs, dogsList);
    });
  }

  Future<void> bulkInsertLitters(List<LittersCompanion> littersList) async {
    await batch((batch) {
      batch.insertAll(litters, littersList);
    });
  }

  Future<int> createLitterWithPuppies(LittersCompanion litter, List<DogsCompanion> puppies) async {
    return await transaction(() async {
      final litterId = await into(litters).insert(litter);
      for (final puppy in puppies) {
        final withLitterId = puppy.copyWith(litterId: Value(litterId));
        await into(dogs).insert(withLitterId);
      }
      return litterId;
    });
  }

  Stream<List<Dog>> watchFilteredDogs({String? sex, String? sortBy}) {
    var query = select(dogs);
    if (sex != null && sex != 'All') {
      query = query..where((tbl) => tbl.sex.equals(sex));
    }
    if (sortBy == 'Name (A-Z)') {
      query = query..orderBy([(d) => OrderingTerm.asc(d.callName)]);
    } else if (sortBy == 'Recent') {
      query = query..orderBy([(d) => OrderingTerm.desc(d.id)]);
    } else if (sortBy == 'Age (Youngest)') {
      query = query..orderBy([(d) => OrderingTerm.desc(d.dateOfBirth)]);
    } else {
      query = query..orderBy([(t) => OrderingTerm(expression: t.callName, mode: OrderingMode.asc)]);
    }
    return query.watch();
  }

  Stream<List<Litter>> watchAllLitters() {
    return (select(litters)..orderBy([(t) => OrderingTerm(expression: t.whelpingDate, mode: OrderingMode.desc)])).watch();
  }

  Stream<List<HeatCycle>> watchAllHeatCycles() {
    return (select(heatCycles)..orderBy([(t) => OrderingTerm(expression: t.startDate, mode: OrderingMode.desc)])).watch();
  }

  Future<List<int>> getDescendantIds(int dogId) async {
    final descendantIds = <int>[];
    final currentIds = <int>[dogId];

    while (currentIds.isNotEmpty) {
      final batchIds = List<int>.from(currentIds);
      currentIds.clear();

      final offspring = await (select(dogs)
            ..where((tbl) => tbl.sireId.isIn(batchIds) | tbl.damId.isIn(batchIds)))
          .get();

      for (var dog in offspring) {
        if (!descendantIds.contains(dog.id)) {
          descendantIds.add(dog.id);
          currentIds.add(dog.id);
        }
      }
    }
    return descendantIds;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'zooped.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
