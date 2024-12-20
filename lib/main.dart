import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/html.dart'; // Per Flutter Web

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebSocket PoE ES',
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
  final String _peerId = "poe_es"; // Cambiare questo ID per ogni peer

  @override
  void initState() {
    super.initState();
    // Connetti al server WebSocket
    _channel = HtmlWebSocketChannel.connect('ws://localhost:8080');

    // Invia il proprio ID al server
    _channel.sink.add(_peerId);

    // Ascolta i messaggi dal server WebSocket
    _channel.stream.listen((message) {
      setState(() {
        // Salva i messaggi ricevuti e visualizzali nell'interfaccia
        _messages.add(message);
      });
    });
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty && _peerController.text.isNotEmpty) {
      // Invia il messaggio al peer specificato
      final targetPeer = _peerController.text;
      final message = '$_peerId->$targetPeer:${_messageController.text}';
      _channel.sink.add(message);

      setState(() {
        _messages.add('Me to $targetPeer: ${_messageController.text}');
        _messageController.clear();
        _peerController.clear();
      });
    }
  }

  @override
  void dispose() {
    _channel.sink
        .close(); // Chiudi la connessione WebSocket quando il widget è distrutto
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WebSocket PoE ES')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ListTile(title: Text(_messages[index]));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _peerController,
                  decoration: const InputDecoration(
                    labelText: 'Peer ID to Send Message',
                  ),
                ),
                const SizedBox(height: 8.0),
                TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                  ),
                ),
                const SizedBox(height: 8.0),
                ElevatedButton(
                  onPressed: _sendMessage,
                  child: const Text('Send Message'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
