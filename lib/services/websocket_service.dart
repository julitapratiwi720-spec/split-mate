import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final _messageController = StreamController<String>.broadcast();

  Stream<String> get messages => _messageController.stream;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  void connect(String billId) {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('wss://echo.websocket.org'),
      );
      _isConnected = true;
      _channel!.stream.listen(
        (msg) => _messageController.add(msg.toString()),
        onError: (e) {
          _isConnected = false;
        },
        onDone: () => _isConnected = false,
      );
    } catch (e) {
      _isConnected = false;
    }
  }

  void sendMessage(String message) {
    if (_isConnected) _channel?.sink.add(message);
  }

  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}