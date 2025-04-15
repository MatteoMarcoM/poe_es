import 'dart:convert';

const String successMessage = 'Valid JSON!';
const String failMessage = 'Error: Invalid JSON!';

class PoAParser {
  final String rawJson;
  late Map<String, dynamic> parsedJson;

  PoAParser(this.rawJson);

  // Extracted information from JSON
  String proofType = '';
  bool transferable = false;
  String publicKeyAlgorithm = '';
  String publicKeyVerification = '';
  String timestampFormat = '';
  String timestampTime = '';
  double gpsLat = 0;
  double gpsLng = 0;
  double gpsAlt = 0;
  String engagementEncoding = '';
  String engagementData = '';
  Map<String, String> sensitiveDataHashMap = {'': ''};
  Map<String, dynamic> otherDataHashMap = {'': ''};

  // NEW
  String? requestId;

  bool validateAndParse() {
    String validationMessage = validate();
    if (validationMessage == successMessage) {
      // Complete parsing of fields
      proofType = parsedJson['proof_type'];
      transferable = parsedJson['transferable'];

      // Parsing public key
      final publicKey = parsedJson['public_key'];
      publicKeyAlgorithm = publicKey['algorithm'];
      publicKeyVerification = publicKey['verification_key'];

      // Parsing timestamp
      final timestamp = parsedJson['timestamp'];
      timestampFormat = timestamp['time_format'];
      timestampTime = timestamp['time'];

      // Parsing GPS coordinates
      final gps = parsedJson['gps'];
      gpsLat = gps['lat'].toDouble();
      gpsLng = gps['lng'].toDouble();
      gpsAlt = gps['alt'].toDouble();

      // Parsing engagement data
      final engagement = parsedJson['engagement_data'];
      engagementEncoding = engagement['encoding'];
      engagementData = engagement['data'];

      // Parsing sensitive data
      final sensitiveData = parsedJson['sensitive_data'];
      sensitiveData.forEach((key, value) {
        sensitiveDataHashMap[key] = value;
      });

      // Parsing other data
      if (parsedJson.containsKey('other_data')) {
        final otherData = parsedJson['other_data'];
        otherData.forEach((key, value) {
          otherDataHashMap[key] = value;
        });
      }

      return true;
    }

    return false;
  }

  String validate() {
    try {
      parsedJson = jsonDecode(rawJson);

      // Verify main keys
      if (!parsedJson.containsKey('proof_type') ||
          parsedJson['proof_type'] is! String) {
        return 'Error: Field "proof_type" is missing or not a string.';
      }
      if (!parsedJson.containsKey('transferable') ||
          parsedJson['transferable'] is! bool) {
        return 'Error: Field "transferable" is missing or not a boolean.';
      }
      if (!parsedJson.containsKey('public_key') ||
          parsedJson['public_key'] is! Map) {
        return 'Error: Field "public_key" is missing or not a valid JSON object.';
      }

      // Verify public key
      final publicKey = parsedJson['public_key'];
      if (!publicKey.containsKey('algorithm') ||
          publicKey['algorithm'] is! String) {
        return 'Error: Field "algorithm" is missing or not a string.';
      }
      if (!publicKey.containsKey('verification_key') ||
          publicKey['verification_key'] is! String) {
        return 'Error: Field "verification_key" is missing or not a string.';
      }

      // Verify timestamp
      if (!parsedJson.containsKey('timestamp') ||
          parsedJson['timestamp'] is! Map) {
        return 'Error: Field "timestamp" is missing or not a valid JSON object.';
      }
      final timestamp = parsedJson['timestamp'];
      if (!timestamp.containsKey('time_format') ||
          timestamp['time_format'] is! String) {
        return 'Error: Field "time_format" is missing or not a string.';
      }
      if (!timestamp.containsKey('time') || timestamp['time'] is! String) {
        return 'Error: Field "time" is missing or not a string.';
      }

      // Verify GPS coordinates
      if (!parsedJson.containsKey('gps') || parsedJson['gps'] is! Map) {
        return 'Error: Field "gps" is missing or not a valid JSON object.';
      }
      final gps = parsedJson['gps'];
      if (!gps.containsKey('lat') || gps['lat'] is! num) {
        return 'Error: Field "lat" is missing or not a number.';
      }
      if (!gps.containsKey('lng') || gps['lng'] is! num) {
        return 'Error: Field "lng" is missing or not a number.';
      }
      if (!gps.containsKey('alt') || gps['alt'] is! num) {
        return 'Error: Field "alt" is missing or not a number.';
      }

      // Verify engagement data
      if (!parsedJson.containsKey('engagement_data') ||
          parsedJson['engagement_data'] is! Map) {
        return 'Error: Field "engagement_data" is missing or not a valid JSON object.';
      }
      final engagementData = parsedJson['engagement_data'];
      if (!engagementData.containsKey('encoding') ||
          engagementData['encoding'] is! String) {
        return 'Error: Field "encoding" is missing or not a string.';
      }
      if (!engagementData.containsKey('data') ||
          engagementData['data'] is! String) {
        return 'Error: Field "data" is missing or not a string.';
      }

      // Verify sensitive data
      if (!parsedJson.containsKey('sensitive_data') ||
          parsedJson['sensitive_data'] is! Map) {
        return 'Error: Field "sensitive_data" is missing or not a valid JSON object.';
      }
      final sensitiveData = parsedJson['sensitive_data'];
      sensitiveData.forEach((key, value) {
        if (key is! String || value is! String) {
          return 'Error: Field "$key" or "$value" in sensitive data is not a string.';
        }
      });

      // Verify other_data (optional)
      if (parsedJson.containsKey('other_data') &&
          parsedJson['other_data'] is! Map) {
        return 'Error: Field "other_data" is not a valid JSON object.';
      }
      final otherData = parsedJson['sensitive_data'];
      otherData.forEach((key, value) {
        if (key is! String || value is! String) {
          return 'Error: Field "$key" or "$value" in other data is not a string.';
        }
      });

      return successMessage;
    } catch (e) {
      return failMessage;
    }
  }
}
