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
          {"rejection": "PoE rejected", "public_key": publicKeyVerification})))
    };

    channel.sink.add(jsonEncode(message));
    onPoERemove(index);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UIComponents.buildDetailsAppBar(context, 'PoE Details'),
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
                      'Valid PoE!', Icons.verified, Colors.green),
                  const SizedBox(height: 20),
                  UIComponents.buildSectionTitle("General Information"),
                  UIComponents.buildTable([
                    UIComponents.buildTableRow('Proof Type', proofType),
                    UIComponents.buildTableRow(
                        'Public Key Algorithm', publicKeyAlgorithm),
                    UIComponents.buildTableRow(
                        'Verification Key', publicKeyVerification),
                    UIComponents.buildTableRow(
                        'Transferable', transferable ? 'Yes' : 'No'),
                    UIComponents.buildTableRow(
                        'Timestamp Format', timestampFormat),
                    UIComponents.buildTableRow('Timestamp Time', timestampTime),
                  ]),
                  const SizedBox(height: 20),
                  UIComponents.buildSectionTitle("GPS Data"),
                  UIComponents.buildTable([
                    UIComponents.buildTableRow('Latitude', gpsLat.toString()),
                    UIComponents.buildTableRow('Longitude', gpsLng.toString()),
                    UIComponents.buildTableRow('Altitude', gpsAlt.toString()),
                  ]),
                  const SizedBox(height: 20),
                  UIComponents.buildSectionTitle("Engagement Data"),
                  UIComponents.buildTable([
                    UIComponents.buildTableRow('Encoding', engagementEncoding),
                    UIComponents.buildTableRow('Data', engagementData),
                    UIComponents.buildTableRow('Decoded Data',
                        utf8.decode(base64Decode(engagementData))),
                  ]),
                  const SizedBox(height: 20),
                  UIComponents.buildSectionTitle("Sensitive Data"),
                  UIComponents.buildDataTable(sensitiveDataHashMap),
                  const SizedBox(height: 20),
                  UIComponents.buildSectionTitle("Other Data"),
                  UIComponents.buildDataTable(otherDataHashMap),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _approvePoE(context),
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text("Approve PoE"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _rejectPoE(context),
                        icon: const Icon(Icons.cancel, color: Colors.white),
                        label: const Text("Reject PoE"),
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
