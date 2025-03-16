import 'dart:convert';
import 'dart:typed_data';
import '../utility/crypto_helper.dart';
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
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title:
            const Text('Dettagli PoE', style: TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
                  Row(
                    children: [
                      const Icon(Icons.verified, color: Colors.green, size: 28),
                      const SizedBox(width: 10),
                      Text(
                        'PoE Valida!',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall!
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle("Informazioni Generali"),
                  _buildTable([
                    _buildTableRow('Tipo di Prova', proofType),
                    _buildTableRow(
                        'Algoritmo Chiave Pubblica', publicKeyAlgorithm),
                    _buildTableRow('Chiave di Verifica', publicKeyVerification),
                    _buildTableRow('Trasferibile', transferable ? 'Sì' : 'No'),
                    _buildTableRow('Formato Timestamp', timestampFormat),
                    _buildTableRow('Orario Timestamp', timestampTime),
                  ]),
                  const SizedBox(height: 20),
                  _buildSectionTitle("Dati GPS"),
                  _buildTable([
                    _buildTableRow('Latitudine', gpsLat.toString()),
                    _buildTableRow('Longitudine', gpsLng.toString()),
                    _buildTableRow('Altitudine', gpsAlt.toString()),
                  ]),
                  const SizedBox(height: 20),
                  _buildSectionTitle("Dati di Engagement"),
                  _buildTable([
                    _buildTableRow('Codifica', engagementEncoding),
                    _buildTableRow('Dati', engagementData),
                    _buildTableRow('Dati Decodificati',
                        utf8.decode(base64Decode(engagementData))),
                  ]),
                  const SizedBox(height: 20),
                  _buildSectionTitle("Dati Sensibili"),
                  _buildDataTable(sensitiveDataHashMap),
                  const SizedBox(height: 20),
                  _buildSectionTitle("Altri Dati"),
                  _buildDataTable(otherDataHashMap),
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

  /// **Titolo della sezione con icona**
  Widget _buildTitle(String text, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// **Titolo di una sezione**
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
        ),
      ),
    );
  }

  /// **Tabella migliorata**
  Widget _buildTable(List<TableRow> rows) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(2),
      },
      border: TableBorder(
        horizontalInside: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      children: rows,
    );
  }

  Widget _buildDataTable(Map<String, dynamic> data) {
    return Table(
      columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(2)},
      border: TableBorder.all(color: Colors.grey.shade300),
      children: data.entries.map((entry) {
        return _buildTableRow(entry.key, entry.value.toString());
      }).toList(),
    );
  }

  /// **Singola riga della tabella**
  TableRow _buildTableRow(String key, String value) {
    return TableRow(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(5),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
            key,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
