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
  TextColumn get contactInfo => text().nullable()();
  TextColumn get localLogoPath => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Dogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get registeredName => text().withLength(min: 1, max: 150).unique()();
  TextColumn get callName => text().withLength(min: 1, max: 50)();
  TextColumn get sex => text().withLength(min: 1, max: 10)(); // 'Male' or 'Female'
  DateTimeColumn get dateOfBirth => dateTime().nullable()();
  TextColumn get microchipNumber => text().nullable().unique()();
  TextColumn get colorMarkings => text().nullable()();
  
  // Self-referencing foreign keys for lineage
  IntColumn get sireId => integer().references(Dogs, #id).nullable()();
  IntColumn get damId => integer().references(Dogs, #id).nullable()();
  IntColumn get litterId => integer().nullable()(); // No foreign key to avoid circular reference
  
  // Certificate metrics
  RealColumn get appraisalScore => real().nullable()();
  RealColumn get inbreedingCoefficient => real().nullable()();
  TextColumn get registerType => text().nullable()(); // 'SP', 'SR', 'B'
  TextColumn get dnaProfileNumber => text().nullable()();
  
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Litters extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sireId => integer().references(Dogs, #id)();
  IntColumn get damId => integer().references(Dogs, #id)();
  DateTimeColumn get matingDate => dateTime().nullable()();
  DateTimeColumn get whelpingDate => dateTime()();
  IntColumn get puppiesBornAlive => integer().withDefault(const Constant(0))();
  IntColumn get puppiesStillborn => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
}

@DriftDatabase(tables: [KennelProfile, Dogs, Litters])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Insert default kennel profile
        await into(kennelProfile).insert(
          KennelProfileCompanion.insert(
            kennelName: 'My Kennel',
          ),
        );
      },
    );
  }

  // Kennel Profile Operations
  Future<KennelProfileData> getKennelProfile() async {
    final profile = await select(kennelProfile).getSingleOrNull();
    if (profile != null) return profile;
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
    await (update(dogs)..where((d) => d.sireId.equals(id))).write(const DogsCompanion(sireId: Value(null)));
    await (update(dogs)..where((d) => d.damId.equals(id))).write(const DogsCompanion(damId: Value(null)));
    await (delete(dogs)..where((d) => d.id.equals(id))).go();
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
    await (update(dogs)..where((d) => d.litterId.equals(id))).write(const DogsCompanion(litterId: Value(null)));
    await (delete(litters)..where((l) => l.id.equals(id))).go();
  }

  Future<List<Dog>> getAllDogs() async {
    return await select(dogs).get();
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
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'zooped.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
