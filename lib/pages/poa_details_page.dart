import 'dart:convert';
import 'dart:typed_data';
import '../utility/crypto_helper.dart';
import '../utility/ui_components.dart';
import 'package:flutter/material.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:web_socket_channel/web_socket_channel.dart';

class PoADetailsPage extends StatelessWidget {
  final String proofType;
  final String publicKeyAlgorithm;
  final String publicKeyVerification;
  final bool transferable;
  final String timestampFormat;
  final String timestampTime;
  final double gpsLat;
  final double gpsLng;
  final double gpsAlt;
  final String engagementEncoding;
  final String engagementData;
  final Map<String, String> sensitiveDataHashMap;
  final Map<String, dynamic> otherDataHashMap;
  final String rawPoeJson;
  final int index;
  final WebSocketChannel channel;
  final Function(int) onPoERemove;
  final pc.RSAPrivateKey privateKey;
  final String requestId;

  const PoADetailsPage({
    super.key,
    required this.proofType,
    required this.publicKeyAlgorithm,
    required this.publicKeyVerification,
    required this.transferable,
    required this.timestampFormat,
    required this.timestampTime,
    required this.gpsLat,
    required this.gpsLng,
    required this.gpsAlt,
    required this.engagementEncoding,
    required this.engagementData,
    required this.sensitiveDataHashMap,
    required this.otherDataHashMap,
    required this.rawPoeJson,
    required this.index,
    required this.channel,
    required this.onPoERemove,
    required this.privateKey,
    required this.requestId,
  });

  void _approvePoE(BuildContext context) {
    Uint8List signatureBytes = CryptoHelper.signJson(rawPoeJson, privateKey);
    String signatureBase64 = base64Encode(signatureBytes);

    final message = {
      "sourcePeer": "poe_es",
      "targetPeer": "poe_client",
      "payload": base64Encode(utf8.encode(jsonEncode({
        "poe": rawPoeJson,
        "signature": signatureBase64,
        "request_id": requestId
      })))
    };

    channel.sink.add(jsonEncode(message));
    onPoERemove(index);
    Navigator.pop(context);
  }

  void _rejectPoE(BuildContext context) {
    final message = {
      "sourcePeer": "poe_es",
      "targetPeer": "poe_client",
      "payload": base64Encode(utf8.encode(jsonEncode(
          {"rejection": "PoE rifiutata", "public_key": publicKeyVerification})))
    };

    channel.sink.add(jsonEncode(message));
    onPoERemove(index);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UIComponents.buildDetailsAppBar(context, 'Dettagli PoE'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UIComponents.buildTitle(
                      'PoE Valida!', Icons.verified, Colors.green),
                  const SizedBox(height: 20),
                  UIComponents.buildSectionTitle("Informazioni Generali"),
                  UIComponents.buildTable([
                    UIComponents.buildTableRow('Tipo di Prova', proofType),
                    UIComponents.buildTableRow(
                        'Algoritmo Chiave Pubblica', publicKeyAlgorithm),
                    UIComponents.buildTableRow(
                        'Chiave di Verifica', publicKeyVerification),
                    UIComponents.buildTableRow(
                        'Trasferibile', transferable ? 'Sì' : 'No'),
                    UIComponents.buildTableRow(
                        'Formato Timestamp', timestampFormat),
                    UIComponents.buildTableRow(
                        'Orario Timestamp', timestampTime),
                  ]),
                  const SizedBox(height: 20),
                  UIComponents.buildSectionTitle("Dati GPS"),
                  UIComponents.buildTable([
                    UIComponents.buildTableRow('Latitudine', gpsLat.toString()),
                    UIComponents.buildTableRow(
                        'Longitudine', gpsLng.toString()),
                    UIComponents.buildTableRow('Altitudine', gpsAlt.toString()),
                  ]),
                  const SizedBox(height: 20),
                  UIComponents.buildSectionTitle("Dati di Engagement"),
                  UIComponents.buildTable([
                    UIComponents.buildTableRow('Codifica', engagementEncoding),
                    UIComponents.buildTableRow('Dati', engagementData),
                    UIComponents.buildTableRow('Dati Decodificati',
                        utf8.decode(base64Decode(engagementData))),
                  ]),
                  const SizedBox(height: 20),
                  UIComponents.buildSectionTitle("Dati Sensibili"),
                  UIComponents.buildDataTable(sensitiveDataHashMap),
                  const SizedBox(height: 20),
                  UIComponents.buildSectionTitle("Altri Dati"),
                  UIComponents.buildDataTable(otherDataHashMap),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _approvePoE(context),
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text("Approva PoE"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _rejectPoE(context),
                        icon: const Icon(Icons.cancel, color: Colors.white),
                        label: const Text("Rifiuta PoE"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
