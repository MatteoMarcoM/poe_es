import 'dart:convert';
import '../utility/poa_parser.dart';
import 'package:flutter/material.dart';
import '../utility/websocket_service.dart';
import '../utility/common_widgets.dart';
import '../pages/poa_details_page.dart';
import 'package:pointycastle/export.dart' as pc;
import '../utility/crypto_helper.dart';
import '../utility/ui_components.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PoE ES',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const WebSocketPage(),
    );
  }
}

class WebSocketPage extends StatefulWidget {
  const WebSocketPage({super.key});
  @override
  State<WebSocketPage> createState() => _WebSocketPageState();
}

class _WebSocketPageState extends State<WebSocketPage> {
  late WebSocketService _webSocketService;
  final List<String> _messages = [];
  final String _peerId = "poe_es";
  final List<PoAParser> _poeList = [];
  late pc.AsymmetricKeyPair<pc.PublicKey, pc.PrivateKey> keyPairES;

  @override
  void initState() {
    super.initState();
    keyPairES = CryptoHelper.generateRSAKeyPair();
    _webSocketService = WebSocketService(
      peerId: _peerId,
      onMessage: _handleMessage,
    );
  }

  // Nuova funzione per gestire i messaggi contenenti dati PoE
  void _handlePoEPayload(Map decodedPayload) {
    final targetJson = {
      "proof_type": "PoA",
      "transferable": false,
      "public_key": {
        "algorithm": "RSA512",
        "verification_key": decodedPayload["public_key"]
      },
      "timestamp": {"time_format": "UTC", "time": decodedPayload["timestamp"]},
      "gps": decodedPayload["gps"],
      "engagement_data": {
        "encoding": "base64",
        "data": base64Encode(utf8.encode(decodedPayload["engagement_data"]))
      },
      "sensitive_data": {
        "matricola": decodedPayload["matricola"],
        "nome": decodedPayload["nome"],
        "cognome": decodedPayload["cognome"],
        "email": decodedPayload["email"]
      },
      "other_data": {"": ""}
    };
    PoAParser parser = PoAParser(jsonEncode(targetJson));
    parser.requestId = decodedPayload['request_id'];
    if (parser.validateAndParse()) {
      setState(() {
        _messages.add('PoE valida e ricevuta correttamente!');
        _poeList.add(parser);
      });
    } else {
      final errorMessage = parser.validate();
      setState(() {
        _messages
            .add('Errore nella validazione del JSON ricevuto: $errorMessage');
      });
    }
  }

  // Nuova funzione per gestire la richiesta della chiave di verifica
  void _handleVerificationKeyPayload(Map decodedPayload) {
    final verificationKey = CryptoHelper.encodeRSAPublicKeyToBase64(
        keyPairES.publicKey as pc.RSAPublicKey);
    final responseJson = jsonEncode({
      "es_verification_key": verificationKey,
    });
    final responseMessage = {
      "sourcePeer": "poe_es",
      "targetPeer": "poe_tp",
      "payload": base64Encode(utf8.encode(responseJson))
    };
    _sendMessage(responseMessage);
    setState(() {
      _messages.add("Chiave di verifica inviata al poe_tp: $verificationKey");
    });
  }

  // Nuova funzione per gestire i messaggi 'hello'
  void _handleHelloPayload(Map decodedPayload, Map data) {
    setState(() {
      _messages.add(decodedPayload['hello']);
    });
    final targetPeerName = data['sourcePeer'];
    _sendMessage(
        _webSocketService.buildHelloMessage(targetPeerName, 'responseHello'));
  }

  // Nuova funzione per gestire i messaggi 'responseHello'
  void _handleResponseHelloPayload(Map decodedPayload) {
    setState(() {
      _messages.add(decodedPayload['responseHello']);
    });
  }

  // Funzione refattorizzata per gestire i messaggi WebSocket
  void _handleMessage(String message) {
    try {
      if (!_isJson(message)) {
        setState(() {
          _messages.add("Errore: $message non è in formato JSON.");
        });
        return;
      }
      final data = jsonDecode(message);
      if (data['payload'] != null) {
        final decodedPayload =
            jsonDecode(utf8.decode(base64Decode(data['payload'])));
        if (decodedPayload.containsKey('matricola') &&
            decodedPayload.containsKey('nome') &&
            decodedPayload.containsKey('cognome') &&
            decodedPayload.containsKey('email') &&
            decodedPayload.containsKey('public_key') &&
            decodedPayload.containsKey('timestamp') &&
            decodedPayload.containsKey('gps') &&
            decodedPayload.containsKey('engagement_data') &&
            decodedPayload.containsKey('request_id')) {
          _handlePoEPayload(decodedPayload);
        } else if (decodedPayload["request"] == "es_verification_key") {
          _handleVerificationKeyPayload(decodedPayload);
        } else if (decodedPayload['hello'] != null) {
          _handleHelloPayload(decodedPayload, data);
        } else if (decodedPayload['responseHello'] != null) {
          _handleResponseHelloPayload(decodedPayload);
        }
      }
    } catch (e) {
      setState(() {
        _messages.add("Errore nel parsing del messaggio: $e");
      });
    }
  }

  void _sendMessage(Map<String, dynamic> message) {
    _webSocketService.sendMessage(message);
  }

  void _sendHello(String targetPeer) {
    _sendMessage(_webSocketService.buildHelloMessage(targetPeer, 'hello'));
  }

  /// Controlla se una stringa è un JSON valido
  bool _isJson(String str) {
    try {
      jsonDecode(str);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _webSocketService.dispose();
    super.dispose();
  }

  // Funzione per rimuovere la PoE dalla lista
  void _removePoE(int index) {
    setState(() {
      _poeList.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UIComponents.buildAppBar(context, 'PoE ES'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Titolo sopra la lista delle PoE da approvare
            const Text(
              "PoE da approvare",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: CommonWidgets.buildPoeCard(
                poEs: _poeList,
                onTap: (poe, index) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PoADetailsPage(
                        proofType: poe.proofType,
                        publicKeyAlgorithm: poe.publicKeyAlgorithm,
                        publicKeyVerification: poe.publicKeyVerification,
                        transferable: poe.transferable,
                        timestampFormat: poe.timestampFormat,
                        timestampTime: poe.timestampTime,
                        gpsLat: poe.gpsLat,
                        gpsLng: poe.gpsLng,
                        gpsAlt: poe.gpsAlt,
                        engagementEncoding: poe.engagementEncoding,
                        engagementData: poe.engagementData,
                        sensitiveDataHashMap: poe.sensitiveDataHashMap,
                        otherDataHashMap: poe.otherDataHashMap,
                        rawPoeJson: poe.rawJson,
                        index: index,
                        channel: _webSocketService.channel,
                        onPoERemove: _removePoE,
                        privateKey: keyPairES.privateKey as pc.RSAPrivateKey,
                        requestId: poe.requestId!,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Titolo sopra la lista dei messaggi ricevuti
            const Text(
              "Messaggi Ricevuti",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: CommonWidgets.buildMessageList(_messages),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _sendHello("poe_client"),
                  icon: const Icon(Icons.network_check),
                  label: const Text('Testa connessione con poe_client'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _sendHello("poe_tp"),
                  icon: const Icon(Icons.network_check),
                  label: const Text('Testa connessione con poe_tp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
