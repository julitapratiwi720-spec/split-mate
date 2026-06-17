import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class WebSocketService {
  IO.Socket? _socket;

  final _messageController = StreamController<String>.broadcast();

  Stream<String> get messages => _messageController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  void connect(String billId) {
    if (_isConnected) return;

    debugPrint('🔌 Connecting WebSocket...');

    _socket = IO.io(
      'http://10.0.2.2:3000', // Emulator Android
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableForceNew()
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      _isConnected = true;

      debugPrint('✅ WebSocket Connected');

      _socket!.emit('join_bill', billId);
    });

    _socket!.on('bill_notification', (data) {
      debugPrint('📢 Notification Received: $data');

      _messageController.add(data.toString());
    });

    _socket!.onConnectError((err) {
      debugPrint('❌ Connect Error: $err');
    });

    _socket!.onError((err) {
      debugPrint('❌ Socket Error: $err');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;

      debugPrint('🔌 WebSocket Disconnected');
    });
  }

  void sendMessage(String message) {
    debugPrint('📤 Send Message Called');

    if (!_isConnected) {
      debugPrint('❌ Socket belum connect');
      return;
    }

    _socket?.emit('bill_created', {
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    });

    debugPrint('✅ Message Sent');
  }

  void disconnect() {
    _socket?.disconnect();
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}