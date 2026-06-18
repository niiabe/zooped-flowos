import 'dart:io';
import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../../features/pedigree/domain/entities/dog.dart' as domain;
import '../../features/pedigree/domain/entities/litter.dart' as domain_litter;
import '../database/app_database.dart';

class CsvService {
  static Future<File> exportDogs(List<domain.Dog> dogs) async {
    final rows = <List<dynamic>>[];

    rows.add([
      'ID', 'Registered Name', 'Call Name', 'Sex', 'Date of Birth',
      'Microchip', 'Color/Markings', 'Sire ID', 'Dam ID', 'Litter ID',
      'Appraisal Score', 'COI', 'Register Type', 'DNA Profile', 'Notes',
    ]);

    for (final dog in dogs) {
      rows.add([
        dog.id,
        dog.registeredName,
        dog.callName,
        dog.sex,
        dog.dateOfBirth?.toIso8601String() ?? '',
        dog.microchipNumber ?? '',
        dog.colorMarkings ?? '',
        dog.sire?.id ?? '',
        dog.dam?.id ?? '',
        dog.litterId ?? '',
        dog.appraisalScore?.toString() ?? '',
        dog.inbreedingCoefficient?.toString() ?? '',
        dog.registerType ?? '',
        dog.dnaProfileNumber ?? '',
        dog.notes ?? '',
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);
    final output = await getApplicationDocumentsDirectory();
    final file = File(p.join(output.path, 'zooped_dogs_export.csv'));
    await file.writeAsString(csv);
    return file;
  }

  static Future<File> exportLitters(List<domain_litter.Litter> litters) async {
    final rows = <List<dynamic>>[];

    rows.add([
      'ID', 'Sire ID', 'Dam ID', 'Mating Date', 'Whelping Date',
      'Puppies Born Alive', 'Puppies Stillborn', 'Notes',
    ]);

    for (final litter in litters) {
      rows.add([
        litter.id,
        litter.sireId,
        litter.damId,
        litter.matingDate?.toIso8601String() ?? '',
        litter.whelpingDate.toIso8601String(),
        litter.puppiesBornAlive,
        litter.puppiesStillborn,
        litter.notes ?? '',
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);
    final output = await getApplicationDocumentsDirectory();
    final file = File(p.join(output.path, 'zooped_litters_export.csv'));
    await file.writeAsString(csv);
    return file;
  }

  static Future<CsvImportResult> importDogsFromCsv(String filePath) async {
    final file = File(filePath);
    final csvString = await file.readAsString();
    final rows = const CsvToListConverter().convert(csvString);

    if (rows.isEmpty) return const CsvImportResult(dogs: []);

    final dogs = <DogsCompanion>[];
    final errors = <String>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 15) {
        errors.add('Row ${i + 1}: insufficient columns (${row.length})');
        continue;
      }

      try {
        final dog = DogsCompanion.insert(
          registeredName: row[1].toString(),
          callName: row[2].toString(),
          sex: row[3].toString(),
          dateOfBirth: Value(row[4].toString().isNotEmpty
              ? DateTime.tryParse(row[4].toString())
              : null),
          microchipNumber: Value(row[5].toString().isEmpty ? null : row[5].toString()),
          colorMarkings: Value(row[6].toString().isEmpty ? null : row[6].toString()),
          sireId: Value(row[7].toString().isEmpty ? null : int.tryParse(row[7].toString())),
          damId: Value(row[8].toString().isEmpty ? null : int.tryParse(row[8].toString())),
          litterId: Value(row[9].toString().isEmpty ? null : int.tryParse(row[9].toString())),
          appraisalScore: Value(row[10].toString().isEmpty ? null : double.tryParse(row[10].toString())),
          inbreedingCoefficient: Value(row[11].toString().isEmpty ? null : double.tryParse(row[11].toString())),
          registerType: Value(row[12].toString().isEmpty ? null : row[12].toString()),
          dnaProfileNumber: Value(row[13].toString().isEmpty ? null : row[13].toString()),
          notes: Value(row[14].toString().isEmpty ? null : row[14].toString()),
        );
        dogs.add(dog);
      } catch (e) {
        errors.add('Row ${i + 1}: $e');
      }
    }

    return CsvImportResult(dogs: dogs, errors: errors);
  }

  static Future<CsvLitterImportResult> importLittersFromCsv(String filePath) async {
    final file = File(filePath);
    final csvString = await file.readAsString();
    final rows = const CsvToListConverter().convert(csvString);

    if (rows.isEmpty) return const CsvLitterImportResult(litters: []);

    final litters = <LittersCompanion>[];
    final errors = <String>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 8) {
        errors.add('Row ${i + 1}: insufficient columns (${row.length})');
        continue;
      }

      try {
        final litter = LittersCompanion.insert(
          sireId: Value(int.parse(row[1].toString())),
          damId: Value(int.parse(row[2].toString())),
          whelpingDate: DateTime.parse(row[4].toString()),
          matingDate: Value(row[3].toString().isNotEmpty
              ? DateTime.tryParse(row[3].toString())
              : null),
          puppiesBornAlive: Value(int.tryParse(row[5].toString()) ?? 0),
          puppiesStillborn: Value(int.tryParse(row[6].toString()) ?? 0),
          notes: Value(row[7].toString().isEmpty ? null : row[7].toString()),
        );
        litters.add(litter);
      } catch (e) {
        errors.add('Row ${i + 1}: $e');
      }
    }

    return CsvLitterImportResult(litters: litters, errors: errors);
  }

  static Future<void> shareCsvFile(File csvFile, String type) async {
    await Share.shareXFiles(
      [XFile(csvFile.path)],
      text: 'ZooPed $type Export',
      subject: 'ZooPed - $type Data Export',
    );
  }

  static Future<void> shareCsvFiles(List<File> csvFiles) async {
    await Share.shareXFiles(
      csvFiles.map((f) => XFile(f.path)).toList(),
      text: 'ZooPed Database Export',
      subject: 'ZooPed - Dogs & Litters Export',
    );
  }
}

class CsvImportResult {
  final List<DogsCompanion> dogs;
  final List<String> errors;
  const CsvImportResult({required this.dogs, this.errors = const []});
}

class CsvLitterImportResult {
  final List<LittersCompanion> litters;
  final List<String> errors;
  const CsvLitterImportResult({required this.litters, this.errors = const []});
}
