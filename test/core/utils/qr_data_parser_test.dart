import 'package:flutter_test/flutter_test.dart';
import 'package:zooped/core/utils/qr_data_parser.dart';

void main() {
  group('QrDataParser', () {
    group('parse', () {
      test('should parse valid JSON QR data', () {
        final qrData = QrDataParser.generateQrData(
          id: 1,
          registeredName: 'Champion Max',
          callName: 'Max',
          breed: 'German Shepherd',
          sex: 'Male',
          microchipNumber: '123456789',
          colorMarkings: 'Black and Tan',
          dateOfBirth: DateTime(2020, 1, 15),
          registerType: 'SR',
          notes: 'Show champion',
        );

        final result = QrDataParser.parse(qrData);

        expect(result, isNotNull);
        expect(result!['registeredName'], 'Champion Max');
        expect(result['callName'], 'Max');
        expect(result['breed'], 'German Shepherd');
        expect(result['sex'], 'Male');
        expect(result['microchipNumber'], '123456789');
        expect(result['colorMarkings'], 'Black and Tan');
        expect(result['dateOfBirth'], DateTime(2020, 1, 15).toIso8601String());
        expect(result['registerType'], 'SR');
        expect(result['notes'], 'Show champion');
      });

      test('should parse QR data with null optional fields', () {
        final qrData = QrDataParser.generateQrData(
          id: 2,
          registeredName: 'Bella',
          callName: 'Bella',
          sex: 'Female',
        );

        final result = QrDataParser.parse(qrData);

        expect(result, isNotNull);
        expect(result!['registeredName'], 'Bella');
        expect(result['callName'], 'Bella');
        expect(result['sex'], 'Female');
        expect(result['breed'], isNull);
        expect(result['microchipNumber'], isNull);
        expect(result['colorMarkings'], isNull);
        expect(result['dateOfBirth'], isNull);
        expect(result['registerType'], isNull);
        expect(result['notes'], isNull);
      });

      test('should parse deep link format', () {
        final deepLink = QrDataParser.generateDeepLink(42);

        final result = QrDataParser.parse(deepLink);

        expect(result, isNotNull);
        expect(result!['dogId'], 42);
      });

      test('should return null for invalid JSON', () {
        final result = QrDataParser.parse('invalid json data');

        expect(result, isNull);
      });

      test('should return null for QR data with wrong type', () {
        final qrData = '{"type":"WRONG","id":1}';
        final result = QrDataParser.parse(qrData);

        expect(result, isNull);
      });

      test('should return null for invalid deep link', () {
        final result = QrDataParser.parse('zooped://invalid');

        expect(result, isNull);
      });

      test('should handle special characters in fields', () {
        final qrData = QrDataParser.generateQrData(
          id: 3,
          registeredName: 'Max | The Great',
          callName: 'Max',
          breed: 'Labrador Retriever',
          sex: 'Male',
          notes: 'First line\nSecond line',
        );

        final result = QrDataParser.parse(qrData);

        expect(result, isNotNull);
        expect(result!['registeredName'], 'Max | The Great');
        expect(result['notes'], 'First line\nSecond line');
      });
    });

    group('isZooPedQrCode', () {
      test('should return true for valid JSON QR code', () {
        final qrData = QrDataParser.generateQrData(
          id: 1,
          registeredName: 'Max',
          callName: 'Max',
          sex: 'Male',
        );

        expect(QrDataParser.isZooPedQrCode(qrData), isTrue);
      });

      test('should return true for valid deep link', () {
        final deepLink = QrDataParser.generateDeepLink(1);

        expect(QrDataParser.isZooPedQrCode(deepLink), isTrue);
      });

      test('should return false for invalid data', () {
        expect(QrDataParser.isZooPedQrCode('random data'), isFalse);
      });

      test('should return false for invalid JSON', () {
        expect(QrDataParser.isZooPedQrCode('{invalid}'), isFalse);
      });
    });

    group('generateQrData', () {
      test('should generate valid JSON string', () {
        final qrData = QrDataParser.generateQrData(
          id: 1,
          registeredName: 'Max',
          callName: 'Max',
          sex: 'Male',
        );

        expect(qrData, isA<String>());
        expect(qrData.startsWith('{'), isTrue);
        expect(qrData.endsWith('}'), isTrue);
      });

      test('should include all required fields', () {
        final qrData = QrDataParser.generateQrData(
          id: 1,
          registeredName: 'Max',
          callName: 'Max',
          sex: 'Male',
        );

        expect(qrData.contains('"type":"ZOOPED"'), isTrue);
        expect(qrData.contains('"id":1'), isTrue);
        expect(qrData.contains('"registeredName":"Max"'), isTrue);
        expect(qrData.contains('"callName":"Max"'), isTrue);
        expect(qrData.contains('"sex":"Male"'), isTrue);
      });
    });

    group('generateDeepLink', () {
      test('should generate valid deep link', () {
        final deepLink = QrDataParser.generateDeepLink(42);

        expect(deepLink, 'zooped://dog/42');
      });

      test('should handle different dog IDs', () {
        expect(QrDataParser.generateDeepLink(0), 'zooped://dog/0');
        expect(QrDataParser.generateDeepLink(999), 'zooped://dog/999');
      });
    });
  });
}