import 'dart:convert';

const String successMessage = 'JSON valido!';
const String failMessage = 'Errore: JSON non valido!';

class PoAParser {
  final String rawJson;
  late Map<String, dynamic> parsedJson;

  PoAParser(this.rawJson);

  // Informazioni estratte dal JSON
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

  bool validateAndParse() {
    String validationMessage = validate();
    if (validationMessage == successMessage) {
      // Parsing completo dei campi
      proofType = parsedJson['proof_type'];
      transferable = parsedJson['transferable'];

      // Parsing della chiave pubblica
      final publicKey = parsedJson['public_key'];
      publicKeyAlgorithm = publicKey['algorithm'];
      publicKeyVerification = publicKey['verification_key'];

      // Parsing del timestamp
      final timestamp = parsedJson['timestamp'];
      timestampFormat = timestamp['time_format'];
      timestampTime = timestamp['time'];

      // Parsing delle coordinate GPS
      final gps = parsedJson['gps'];
      gpsLat = gps['lat'].toDouble();
      gpsLng = gps['lng'].toDouble();
      gpsAlt = gps['alt'].toDouble();

      // Parsing dei dati di engagement
      final engagement = parsedJson['engagement_data'];
      engagementEncoding = engagement['encoding'];
      engagementData = engagement['data'];

      // Parsing dei dati sensibili
      final sensitiveData = parsedJson['sensitive_data'];
      sensitiveData.forEach((key, value) {
        if (key.startsWith('data_')) {
          sensitiveDataHashMap[key] = value;
        }
      });

      // Parsing di other_data
      if (parsedJson.containsKey('other_data')) {
        otherDataHashMap = parsedJson['other_data'];
      }

      return true;
    }

    return false;
  }

  String validate() {
    try {
      parsedJson = jsonDecode(rawJson);

      // Verifica delle chiavi principali
      if (!parsedJson.containsKey('proof_type') ||
          parsedJson['proof_type'] is! String) {
        return 'Errore: Il campo "proof_type" è mancante o non è una stringa.';
      }
      if (!parsedJson.containsKey('transferable') ||
          parsedJson['transferable'] is! bool) {
        return 'Errore: Il campo "transferable" è mancante o non è un booleano.';
      }
      if (!parsedJson.containsKey('public_key') ||
          parsedJson['public_key'] is! Map) {
        return 'Errore: Il campo "public_key" è mancante o non è un oggetto.';
      }

      // Verifica della chiave pubblica
      final publicKey = parsedJson['public_key'];
      if (!publicKey.containsKey('algorithm') ||
          publicKey['algorithm'] is! String) {
        return 'Errore: Il campo "algorithm" è mancante o non è una stringa.';
      }
      if (!publicKey.containsKey('verification_key') ||
          publicKey['verification_key'] is! String) {
        return 'Errore: Il campo "verification_key" è mancante o non è una stringa.';
      }

      // Verifica del timestamp
      if (!parsedJson.containsKey('timestamp') ||
          parsedJson['timestamp'] is! Map) {
        return 'Errore: Il campo "timestamp" è mancante o non è un oggetto.';
      }
      final timestamp = parsedJson['timestamp'];
      if (!timestamp.containsKey('time_format') ||
          timestamp['time_format'] is! String) {
        return 'Errore: Il campo "time_format" è mancante o non è una stringa.';
      }
      if (!timestamp.containsKey('time') || timestamp['time'] is! String) {
        return 'Errore: Il campo "time" è mancante o non è una stringa.';
      }

      // Verifica delle coordinate GPS
      if (!parsedJson.containsKey('gps') || parsedJson['gps'] is! Map) {
        return 'Errore: Il campo "gps" è mancante o non è un oggetto.';
      }
      final gps = parsedJson['gps'];
      if (!gps.containsKey('lat') || gps['lat'] is! num) {
        return 'Errore: Il campo "lat" è mancante o non è un numero.';
      }
      if (!gps.containsKey('lng') || gps['lng'] is! num) {
        return 'Errore: Il campo "lng" è mancante o non è un numero.';
      }
      if (!gps.containsKey('alt') || gps['alt'] is! num) {
        return 'Errore: Il campo "alt" è mancante o non è un numero.';
      }

      // Verifica dei dati di engagement
      if (!parsedJson.containsKey('engagement_data') ||
          parsedJson['engagement_data'] is! Map) {
        return 'Errore: Il campo "engagement_data" è mancante o non è un oggetto.';
      }
      final engagementData = parsedJson['engagement_data'];
      if (!engagementData.containsKey('encoding') ||
          engagementData['encoding'] is! String) {
        return 'Errore: Il campo "encoding" è mancante o non è una stringa.';
      }
      if (!engagementData.containsKey('data') ||
          engagementData['data'] is! String) {
        return 'Errore: Il campo "data" è mancante o non è una stringa.';
      }

      // Verifica dei dati sensibili
      if (!parsedJson.containsKey('sensitive_data') ||
          parsedJson['sensitive_data'] is! Map) {
        return 'Errore: Il campo "sensitive_data" è mancante o non è un oggetto.';
      }
      final sensitiveData = parsedJson['sensitive_data'];
      sensitiveData.forEach((key, value) {
        if (key.startsWith('data_') && value is! String) {
          return 'Errore: Il campo "$key" nei dati sensibili non è una stringa.';
        }
      });

      // Verifica di other_data (facoltativa)
      if (parsedJson.containsKey('other_data') &&
          parsedJson['other_data'] is! Map) {
        return 'Errore: Il campo "other_data" non è un oggetto JSON valido.';
      }

      return successMessage;
    } catch (e) {
      return failMessage;
    }
  }
}
