import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/constants.dart';

class WebSocketService {
  static WebSocketChannel? _channel;
  static Timer? _reconnectTimer;
  static String? _token;
  static Function(Map<String, dynamic>)? onMessage;
  static Function? onConnected;
  static Function? onDisconnected;
  static bool _disposed = false;
  static bool _connected = false;

  static void connect(String token) {
    if (_connected) return;
    _token = token;
    _disposed = false;
    _doConnect();
  }

  static void _doConnect() {
    if (_token == null || _disposed) return;

    final baseUrl = AppConstants.apiBaseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
    final wsUrl = '$baseUrl/ws?token=$_token';

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _connected = true;
      onConnected?.call();
      _channel!.stream.listen(
        (data) {
          try {
            final msg = jsonDecode(data as String) as Map<String, dynamic>;
            onMessage?.call(msg);
          } catch (_) {}
        },
        onDone: () {
          _connected = false;
          onDisconnected?.call();
          _scheduleReconnect();
        },
        onError: (_) {
          _connected = false;
          onDisconnected?.call();
          _scheduleReconnect();
        },
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  static void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 10), _doConnect);
  }

  static void disconnect() {
    _disposed = true;
    _connected = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }
}
