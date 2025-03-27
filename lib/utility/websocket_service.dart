import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/html.dart';

class WebSocketService {
  late WebSocketChannel channel;
  final String peerId;
  final Function(String) onMessage;

  WebSocketService({
    required this.peerId,
    required this.onMessage,
  }) {
    connect();
  }

  void connect() {
    channel = HtmlWebSocketChannel.connect('ws://localhost:8080');
    channel.sink.add(peerId);

    channel.stream.listen((message) {
      onMessage(message);
    });
  }

  void sendMessage(Map<String, dynamic> message) {
    channel.sink.add(jsonEncode(message));
  }

  Map<String, dynamic> buildHelloMessage(
      String targetPeer, String messageKeyString) {
    if (messageKeyString != "hello" && messageKeyString != "responseHello") {
      return {
        "sourcePeer": peerId,
        "targetPeer": targetPeer,
        "payload": base64Encode(utf8.encode(jsonEncode({
          "error": "Errore: Il formato del messaggio di 'hello' e' sbagliato."
        }))),
      };
    } else {
      return {
        "sourcePeer": peerId,
        "targetPeer": targetPeer,
        "payload": base64Encode(
            utf8.encode(jsonEncode({messageKeyString: "Ciao da $peerId."}))),
      };
    }
  }

  void dispose() {
    channel.sink.close();
  }
}
