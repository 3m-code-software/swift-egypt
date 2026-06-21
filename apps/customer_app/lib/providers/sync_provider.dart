import 'package:flutter/foundation.dart';
import '../services/sync_service.dart';
import '../services/websocket_service.dart';

class SyncProvider extends ChangeNotifier {
  bool _isOnline = true;
  int _pendingCount = 0;
  bool _isSyncing = false;

  bool get isOnline => _isOnline;
  int get pendingCount => _pendingCount;
  bool get isSyncing => _isSyncing;
  bool get hasPending => _pendingCount > 0;

  Function(Map<String, dynamic>)? onWebSocketMessage;

  SyncProvider() {
    SyncService.onQueueChanged = () {
      refresh();
    };
    _init();
  }

  Future<void> _init() async {
    _isOnline = await SyncService.isConnected();
    _pendingCount = await SyncService.getPendingCount();
    notifyListeners();

    SyncService.startListening(
      onSync: () {
        refresh();
      },
    );
  }

  void connectWebSocket(String token) {
    WebSocketService.onConnected = () {
      _isOnline = true;
      notifyListeners();
    };
    WebSocketService.onDisconnected = () {
      _isOnline = false;
      notifyListeners();
    };
    WebSocketService.onMessage = (msg) {
      onWebSocketMessage?.call(msg);
    };
    WebSocketService.connect(token);
  }

  Future<void> refresh() async {
    _isOnline = await SyncService.isConnected();
    _pendingCount = await SyncService.getPendingCount();
    notifyListeners();
  }

  Future<void> triggerSync() async {
    if (_isSyncing) return;
    _isSyncing = true;
    notifyListeners();

    await SyncService.syncPendingActions();
    await refresh();
    _isSyncing = false;
    notifyListeners();
  }

  void updateOnlineStatus(bool online) {
    _isOnline = online;
    notifyListeners();
  }

  @override
  void dispose() {
    WebSocketService.disconnect();
    SyncService.stopListening();
    super.dispose();
  }
}
