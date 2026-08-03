import 'dart:convert';

class QrDataParser {
  static const String _typeKey = 'type';
  static const String _typeValue = 'ZOOPED';

  static Map<String, dynamic>? parse(String data) {
    try {
      if (data.startsWith('{')) {
        return _parseJson(data);
      } else if (data.startsWith('zooped://dog/')) {
        return _parseDeepLink(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Map<String, dynamic>? _parseJson(String data) {
    final jsonData = jsonDecode(data) as Map<String, dynamic>;

    if (jsonData[_typeKey] != _typeValue) {
      return null;
    }

    return {
      'registeredName': jsonData['registeredName'] as String?,
      'callName': jsonData['callName'] as String?,
      'breed': jsonData['breed'] as String?,
      'sex': jsonData['sex'] as String?,
      'microchipNumber': jsonData['microchipNumber'] as String?,
      'colorMarkings': jsonData['colorMarkings'] as String?,
      'dateOfBirth': jsonData['dateOfBirth'] as String?,
      'registerType': jsonData['registerType'] as String?,
      'notes': jsonData['notes'] as String?,
    };
  }

  static Map<String, dynamic>? _parseDeepLink(String url) {
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;

    if (pathSegments.isNotEmpty) {
      final dogId = int.tryParse(pathSegments.first);
      if (dogId != null) {
        return {'dogId': dogId};
      }
    }
    return null;
  }

  static String generateQrData({
    required int id,
    required String registeredName,
    required String callName,
    String? breed,
    required String sex,
    String? microchipNumber,
    String? colorMarkings,
    DateTime? dateOfBirth,
    String? registerType,
    String? notes,
  }) {
    return jsonEncode({
      _typeKey: _typeValue,
      'id': id,
      'registeredName': registeredName,
      'callName': callName,
      'breed': breed,
      'sex': sex,
      'microchipNumber': microchipNumber,
      'colorMarkings': colorMarkings,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'registerType': registerType,
      'notes': notes,
    });
  }

  static String generateDeepLink(int dogId) {
    return 'zooped://dog/$dogId';
  }

  static bool isZooPedQrCode(String data) {
    if (data.startsWith('{')) {
      try {
        final jsonData = jsonDecode(data) as Map<String, dynamic>;
        return jsonData[_typeKey] == _typeValue;
      } catch (e) {
        return false;
      }
    }
    return data.startsWith('zooped://dog/');
  }
}