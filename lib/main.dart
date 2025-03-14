import 'dart:convert';
import '../utility/poa_parser.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/html.dart'; // Per Flutter Web
import '../pages/poa_details_page.dart';
import 'package:pointycastle/export.dart' as pc;
import '../utility/crypto_helper.dart';

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
  late WebSocketChannel _channel;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _peerController = TextEditingController();
  final List<String> _messages = [];
  final String _peerId = "poe_es"; // ID del peer
  final String _targetPeer = "poe_client"; // Peer destinatario fisso
  final List<PoAParser> _poeList = []; // Lista di oggetti PoAParser
  late pc.AsymmetricKeyPair<pc.PublicKey, pc.PrivateKey> keyPairES;

  @override
  void initState() {
    super.initState();
    keyPairES = CryptoHelper.generateRSAKeyPair();
    // Connetti al server WebSocket
    _channel = HtmlWebSocketChannel.connect('ws://localhost:8080');
    // Invia il proprio ID al server
    _channel.sink.add(_peerId);
    // Ascolta i messaggi dal server
    _channel.stream.listen((message) {
      _handleMessage(message);
    });
  }

  // per inviare un messaggio dato il json
  void _sendMessage(Map<String, dynamic> message) {
    _channel.sink.add(jsonEncode(message));
  }

  /// Invia un messaggio di 'hello' per capire se e' connesso agli altri peers
  // per creare il json di un messaggio hello
  Map<String, dynamic> _buildHelloMessage(
      String targetPeer, String messageKeyString) {
    if (messageKeyString != "hello" && messageKeyString != "responseHello") {
      return {
        "sourcePeer": _peerId,
        "targetPeer": targetPeer,
        "payload": base64Encode(utf8.encode(jsonEncode({
          "error": "Errore: Il formato del messaggio di 'hello' e' sbagliato."
        }))),
      };
    } else {
      return {
        "sourcePeer": _peerId,
        "targetPeer": targetPeer,
        "payload": base64Encode(
            utf8.encode(jsonEncode({messageKeyString: "Ciao da $_peerId."}))),
      };
    }
  }

  // Funzione per inviare un messaggio hello al peer target
  void _sendHello(String targetPeer) {
    _sendMessage(_buildHelloMessage(targetPeer, 'hello'));
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

  /// Gestisce i messaggi ricevuti dal WebSocket
  /// Gestisce i messaggi ricevuti dal WebSocket
  void _handleMessage(String message) {
    try {
      // Controlla se il messaggio è un JSON valido
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

        // Nuovo branch: se il payload contiene i dati della PoE
        if (decodedPayload.containsKey('matricola') &&
            decodedPayload.containsKey('nome') &&
            decodedPayload.containsKey('cognome') &&
            decodedPayload.containsKey('email') &&
            decodedPayload.containsKey('public_key') &&
            decodedPayload.containsKey('timestamp') &&
            decodedPayload.containsKey('gps') &&
            decodedPayload.containsKey('engagement_data') &&
            decodedPayload.containsKey('request_id')) {
          // Costruisci il JSON target con i valori ricevuti
          final targetJson = {
            "proof_type": "PoA",
            "transferable": false,
            "public_key": {
              "algorithm": "RSA512",
              "verification_key": decodedPayload["public_key"]
            },
            "timestamp": {
              "time_format": "UTC",
              "time": decodedPayload["timestamp"]
            },
            "gps": decodedPayload["gps"],
            "engagement_data": {
              "encoding": "base64",
              "data":
                  base64Encode(utf8.encode(decodedPayload["engagement_data"]))
            },
            "sensitive_data": {
              "matricola": decodedPayload["matricola"],
              "nome": decodedPayload["nome"],
              "cognome": decodedPayload["cognome"],
              "email": decodedPayload["email"]
            },
            "other_data": {"": ""}
          };
          // Crea un oggetto PoAParser e verifica se è valido
          PoAParser parser = PoAParser(jsonEncode(targetJson));
          // aggiungi il request id
          parser.requestId = decodedPayload['request_id'];
          if (parser.validateAndParse()) {
            setState(() {
              _messages.add('PoE valida e ricevuta correttamente!');
              _poeList.add(parser); // Aggiunge il nuovo PoAParser alla lista
            });
          } else {
            final errorMessage = parser.validate();
            setState(() {
              _messages.add(
                  'Errore nella validazione del JSON ricevuto: $errorMessage');
            });
          }
        } else if (decodedPayload["request"] == "es_verification_key") {
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
            _messages
                .add("Chiave di verifica inviata al poe_tp: $verificationKey");
          });
        } else if (decodedPayload['hello'] != null) {
          // scrivi il saluto in chat
          setState(() {
            _messages.add(decodedPayload['hello']);
          });
          // rispondo al saluto
          final targetPeerName = data['sourcePeer'];
          _sendMessage(_buildHelloMessage(targetPeerName, 'responseHello'));
        } else if (decodedPayload['responseHello'] != null) {
          // scrivi il saluto in chat
          setState(() {
            _messages.add(decodedPayload['responseHello']);
          });
        }
      }
    } catch (e) {
      setState(() {
        _messages.add("Errore nel parsing del messaggio: $e");
      });
    }
  }

  @override
  void dispose() {
    _channel.sink.close();
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
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('PoE ES'),
      ),
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

            // Box con la ListView delle PoE da approvare
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListView.builder(
                    itemCount: _poeList.length,
                    itemBuilder: (context, index) {
                      final poe = _poeList[index];
                      return ListTile(
                        leading: Icon(Icons.assignment, color: Colors.orange),
                        title: Text(
                          'PoE #${index + 1} - ${poe.proofType}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Public Key: ${poe.publicKeyVerification}',
                          overflow: TextOverflow.ellipsis,
                        ),
                        tileColor: Colors.grey[200],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        trailing: Icon(Icons.arrow_forward, color: Colors.blue),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PoADetailsPage(
                                proofType: poe.proofType,
                                publicKeyAlgorithm: poe.publicKeyAlgorithm,
                                publicKeyVerification:
                                    poe.publicKeyVerification,
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
                                channel: _channel,
                                onPoERemove: _removePoE,
                                privateKey:
                                    keyPairES.privateKey as pc.RSAPrivateKey,
                                requestId: poe.requestId!,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
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

            // Box con la ListView dei messaggi ricevuti
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: Icon(Icons.message, color: Colors.deepPurple),
                        title: Text(_messages[index]),
                        tileColor: Colors.grey[200],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Bottoni migliorati con icone e colori
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _sendHello("poe_client"),
                  icon: Icon(Icons.network_check),
                  label: const Text('Testa connessione con poe_client'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _sendHello("poe_tp"),
                  icon: Icon(Icons.network_check),
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
