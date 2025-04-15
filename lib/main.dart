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
      home: const ESModule(),
    );
  }
}

class ESModule extends StatefulWidget {
  const ESModule({super.key});
  @override
  State<ESModule> createState() => _ESModuleState();
}

class _ESModuleState extends State<ESModule> {
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

  // New function to handle messages containing PoE data
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
        "registration_number": decodedPayload["registration_number"],
        "name": decodedPayload["name"],
        "surname": decodedPayload["surname"],
        "email": decodedPayload["email"]
      },
      "other_data": {"": ""}
    };
    PoAParser parser = PoAParser(jsonEncode(targetJson));
    parser.requestId = decodedPayload['request_id'];
    if (parser.validateAndParse()) {
      setState(() {
        _messages.add('PoE valid and received correctly!');
        _poeList.add(parser);
      });
    } else {
      final errorMessage = parser.validate();
      setState(() {
        _messages.add('Error validating received JSON: $errorMessage');
      });
    }
  }

  // New function to handle the verification key request
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
      _messages.add("Verification key sent to poe_tp: $verificationKey");
    });
  }

  // New function to handle 'hello' messages
  void _handleHelloPayload(Map decodedPayload, Map data) {
    setState(() {
      _messages.add(decodedPayload['hello']);
    });
    final targetPeerName = data['sourcePeer'];
    _sendMessage(
        _webSocketService.buildHelloMessage(targetPeerName, 'responseHello'));
  }

  // New function to handle 'responseHello' messages
  void _handleResponseHelloPayload(Map decodedPayload) {
    setState(() {
      _messages.add(decodedPayload['responseHello']);
    });
  }

  // Refactored function to handle WebSocket messages
  void _handleMessage(String message) {
    try {
      if (!_isJson(message)) {
        setState(() {
          _messages.add("Error: $message is not in JSON format.");
        });
        return;
      }
      final data = jsonDecode(message);
      if (data['payload'] != null) {
        final decodedPayload =
            jsonDecode(utf8.decode(base64Decode(data['payload'])));
        if (decodedPayload.containsKey('registration_number') &&
            decodedPayload.containsKey('name') &&
            decodedPayload.containsKey('surname') &&
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
        _messages.add("Error parsing message: $e");
      });
    }
  }

  void _sendMessage(Map<String, dynamic> message) {
    _webSocketService.sendMessage(message);
  }

  void _sendHello(String targetPeer) {
    _sendMessage(_webSocketService.buildHelloMessage(targetPeer, 'hello'));
  }

  /// Check if a string is valid JSON
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

  // Function to remove the PoE from the list
  void _removePoE(int index) {
    setState(() {
      _poeList.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UIComponents.buildDefaultAppBar(context, 'PoE ES'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title above the list of PoEs to approve
            const Text(
              "PoE to Approve",
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

            // Title above the list of received messages
            const Text(
              "Received Messages",
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
                  label: const Text('Test connection with poe_client'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _sendHello("poe_tp"),
                  icon: const Icon(Icons.network_check),
                  label: const Text('Test connection with poe_tp'),
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
