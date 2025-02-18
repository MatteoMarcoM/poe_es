import 'dart:convert';

import 'package:flutter/material.dart';

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
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('PoE Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Torna alla pagina JsonPage
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          // Per gestire lo scroll in caso di contenuti lunghi
          child: Card(
            elevation: 5, // Aggiunge un'ombra alla scheda
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'La PoE è valida!',
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge, // Stile del titolo
                  ),
                  const SizedBox(height: 20),
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(1), // Colonna delle chiavi
                      1: FlexColumnWidth(2), // Colonna dei valori
                    },
                    border: TableBorder.all(
                        color: Colors.grey.shade300), // Bordo della tabella
                    children: [
                      _buildTableRow('Proof Type', proofType),
                      _buildTableRow(
                          'Public Key Algorithm', publicKeyAlgorithm),
                      _buildTableRow(
                          'Public Verification Key', publicKeyVerification),
                      _buildTableRow('Transferable', '$transferable'),
                      _buildTableRow('Timestamp Format', timestampFormat),
                      _buildTableRow('Timestamp Time', timestampTime),
                      _buildTableRow('GPS Latitude', gpsLat.toString()),
                      _buildTableRow('GPS Longitude', gpsLng.toString()),
                      _buildTableRow('GPS Altitude', gpsAlt.toString()),
                      _buildTableRow('Engagement Encoding', engagementEncoding),
                      _buildTableRow('Engagement Data', engagementData),
                      _buildTableRow('Engagement Data Decoded',
                          utf8.decode(base64Decode(engagementData))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Dati Sensibili:',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall, // Stile dei dati sensibili
                  ),
                  const SizedBox(height: 10),
                  _buildSensitiveDataTable(),
                  const SizedBox(height: 20),
                  Text(
                    'Altri Dati:',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall, // Stile degli altri dati
                  ),
                  const SizedBox(height: 10),
                  _buildOtherDataTable(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Funzione per creare una riga della tabella
  TableRow _buildTableRow(String key, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            key,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  // Tabella per i dati sensibili
  Widget _buildSensitiveDataTable() {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(2),
      },
      border: TableBorder.all(color: Colors.grey.shade300),
      children: sensitiveDataHashMap.entries.map((entry) {
        return _buildTableRow(entry.key, entry.value);
      }).toList(),
    );
  }

  // Tabella per altri dati
  Widget _buildOtherDataTable() {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(2),
      },
      border: TableBorder.all(color: Colors.grey.shade300),
      children: otherDataHashMap.entries.map((entry) {
        return _buildTableRow(entry.key, entry.value.toString());
      }).toList(),
    );
  }
}
