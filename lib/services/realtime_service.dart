import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_client.dart';

class RealtimeService {
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  StreamSubscription? _sub;
  final _systemsController = StreamController<List<dynamic>>.broadcast();
  final _statusController = StreamController<String>.broadcast();

  Stream<List<dynamic>> get systemsStream => _systemsController.stream;
  Stream<String> get statusStream => _statusController.stream;

  bool get isConnected => _channel != null;

  void connect() {
    _cleanup();
    try {
      _channel = WebSocketChannel.connect(Uri.parse(ApiClient.wsUrl));
      _statusController.add('connected');

      _sub = _channel!.stream.listen(
        (msg) {
          final data = jsonDecode(msg as String);
          if (data['type'] == 'systems_update') {
            _systemsController.add(List<dynamic>.from(data['data']));
          }
        },
        onError: (_) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _statusController.add('disconnected');
    _cleanup();
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      _statusController.add('reconnecting');
      connect();
    });
  }

  void _cleanup() {
    _sub?.cancel();
    _sub = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _cleanup();
    _systemsController.close();
    _statusController.close();
  }
}
