import 'package:flutter_test/flutter_test.dart';
import 'package:zooped/features/pedigree/domain/entities/dog.dart';

void main() {
  group('Dog Entity', () {
    test('should create a dog with required fields', () {
      final dog = Dog(
        id: 1,
        registeredName: 'Champion Max',
        callName: 'Max',
        sex: 'Male',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(dog.id, 1);
      expect(dog.registeredName, 'Champion Max');
      expect(dog.callName, 'Max');
      expect(dog.sex, 'Male');
      expect(dog.createdAt, DateTime(2024, 1, 1));
      expect(dog.breed, isNull);
      expect(dog.dateOfBirth, isNull);
      expect(dog.microchipNumber, isNull);
      expect(dog.colorMarkings, isNull);
      expect(dog.sire, isNull);
      expect(dog.dam, isNull);
      expect(dog.litterId, isNull);
      expect(dog.appraisalScore, isNull);
      expect(dog.inbreedingCoefficient, isNull);
      expect(dog.registerType, isNull);
      expect(dog.dnaProfileNumber, isNull);
      expect(dog.photoPath, isNull);
      expect(dog.saleStatus, isNull);
      expect(dog.notes, isNull);
    });

    test('should create a dog with all fields', () {
      final sire = Dog(
        id: 2,
        registeredName: 'Sire Dog',
        callName: 'Sire',
        sex: 'Male',
        createdAt: DateTime(2023, 1, 1),
      );

      final dam = Dog(
        id: 3,
        registeredName: 'Dam Dog',
        callName: 'Dam',
        sex: 'Female',
        createdAt: DateTime(2023, 1, 1),
      );

      final dog = Dog(
        id: 1,
        registeredName: 'Champion Max',
        callName: 'Max',
        breed: 'German Shepherd',
        sex: 'Male',
        dateOfBirth: DateTime(2020, 1, 15),
        microchipNumber: '123456789',
        colorMarkings: 'Black and Tan',
        sire: sire,
        dam: dam,
        litterId: 1,
        appraisalScore: 95.0,
        inbreedingCoefficient: 5.2,
        registerType: 'SR',
        dnaProfileNumber: 'DNA123',
        photoPath: '/path/to/photo.jpg',
        saleStatus: 'Owned',
        notes: 'Show champion',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(dog.id, 1);
      expect(dog.registeredName, 'Champion Max');
      expect(dog.callName, 'Max');
      expect(dog.breed, 'German Shepherd');
      expect(dog.sex, 'Male');
      expect(dog.dateOfBirth, DateTime(2020, 1, 15));
      expect(dog.microchipNumber, '123456789');
      expect(dog.colorMarkings, 'Black and Tan');
      expect(dog.sire, sire);
      expect(dog.dam, dam);
      expect(dog.litterId, 1);
      expect(dog.appraisalScore, 95.0);
      expect(dog.inbreedingCoefficient, 5.2);
      expect(dog.registerType, 'SR');
      expect(dog.dnaProfileNumber, 'DNA123');
      expect(dog.photoPath, '/path/to/photo.jpg');
      expect(dog.saleStatus, 'Owned');
      expect(dog.notes, 'Show champion');
      expect(dog.createdAt, DateTime(2024, 1, 1));
    });

    group('isFoundationDog', () {
      test('should return true when sire and dam are null', () {
        final dog = Dog(
          id: 1,
          registeredName: 'Max',
          callName: 'Max',
          sex: 'Male',
          createdAt: DateTime(2024, 1, 1),
        );

        expect(dog.isFoundationDog, isTrue);
      });

      test('should return false when sire is present', () {
        final sire = Dog(
          id: 2,
          registeredName: 'Sire',
          callName: 'Sire',
          sex: 'Male',
          createdAt: DateTime(2023, 1, 1),
        );

        final dog = Dog(
          id: 1,
          registeredName: 'Max',
          callName: 'Max',
          sex: 'Male',
          sire: sire,
          createdAt: DateTime(2024, 1, 1),
        );

        expect(dog.isFoundationDog, isFalse);
      });

      test('should return false when dam is present', () {
        final dam = Dog(
          id: 3,
          registeredName: 'Dam',
          callName: 'Dam',
          sex: 'Female',
          createdAt: DateTime(2023, 1, 1),
        );

        final dog = Dog(
          id: 1,
          registeredName: 'Max',
          callName: 'Max',
          sex: 'Male',
          dam: dam,
          createdAt: DateTime(2024, 1, 1),
        );

        expect(dog.isFoundationDog, isFalse);
      });

      test('should return false when both sire and dam are present', () {
        final sire = Dog(
          id: 2,
          registeredName: 'Sire',
          callName: 'Sire',
          sex: 'Male',
          createdAt: DateTime(2023, 1, 1),
        );

        final dam = Dog(
          id: 3,
          registeredName: 'Dam',
          callName: 'Dam',
          sex: 'Female',
          createdAt: DateTime(2023, 1, 1),
        );

        final dog = Dog(
          id: 1,
          registeredName: 'Max',
          callName: 'Max',
          sex: 'Male',
          sire: sire,
          dam: dam,
          createdAt: DateTime(2024, 1, 1),
        );

        expect(dog.isFoundationDog, isFalse);
      });
    });

    group('copyWith', () {
      test('should copy with no changes', () {
        final original = Dog(
          id: 1,
          registeredName: 'Max',
          callName: 'Max',
          sex: 'Male',
          createdAt: DateTime(2024, 1, 1),
        );

        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.registeredName, original.registeredName);
        expect(copy.callName, original.callName);
        expect(copy.sex, original.sex);
        expect(copy.createdAt, original.createdAt);
      });

      test('should copy with changed fields', () {
        final original = Dog(
          id: 1,
          registeredName: 'Max',
          callName: 'Max',
          sex: 'Male',
          createdAt: DateTime(2024, 1, 1),
        );

        final copy = original.copyWith(
          registeredName: 'Champion Max',
          callName: 'Champ',
          breed: 'German Shepherd',
        );

        expect(copy.id, original.id);
        expect(copy.registeredName, 'Champion Max');
        expect(copy.callName, 'Champ');
        expect(copy.breed, 'German Shepherd');
        expect(copy.sex, original.sex);
        expect(copy.createdAt, original.createdAt);
      });

      test('should copy with cleared sire', () {
        final sire = Dog(
          id: 2,
          registeredName: 'Sire',
          callName: 'Sire',
          sex: 'Male',
          createdAt: DateTime(2023, 1, 1),
        );

        final original = Dog(
          id: 1,
          registeredName: 'Max',
          callName: 'Max',
          sex: 'Male',
          sire: sire,
          createdAt: DateTime(2024, 1, 1),
        );

        final copy = original.copyWith(clearSire: true);

        expect(copy.sire, isNull);
      });

      test('should copy with cleared dam', () {
        final dam = Dog(
          id: 3,
          registeredName: 'Dam',
          callName: 'Dam',
          sex: 'Female',
          createdAt: DateTime(2023, 1, 1),
        );

        final original = Dog(
          id: 1,
          registeredName: 'Max',
          callName: 'Max',
          sex: 'Male',
          dam: dam,
          createdAt: DateTime(2024, 1, 1),
        );

        final copy = original.copyWith(clearDam: true);

        expect(copy.dam, isNull);
      });

      test('should copy with cleared litterId', () {
        final original = Dog(
          id: 1,
          registeredName: 'Max',
          callName: 'Max',
          sex: 'Male',
          litterId: 1,
          createdAt: DateTime(2024, 1, 1),
        );

        final copy = original.copyWith(clearLitterId: true);

        expect(copy.litterId, isNull);
      });
    });
  });
}