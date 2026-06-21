import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';
import '../core/constants.dart';

class SyncService {
  static final _storage = const FlutterSecureStorage();
  static final _connectivity = Connectivity();
  static StreamSubscription<List<ConnectivityResult>>? _subscription;
  static bool _isSyncing = false;
  static Function? onSyncComplete;
  static Function? onQueueChanged;
  static ApiService? _api;

  static void setApi(ApiService api) {
    _api = api;
  }

  static Future<bool> isConnected() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  static Stream<List<ConnectivityResult>> get connectivityStream =>
      _connectivity.onConnectivityChanged;

  static void startListening({Function? onSync}) {
    onSyncComplete = onSync;
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final connected = results.any((r) => r != ConnectivityResult.none);
      if (connected) {
        syncPendingActions();
      }
    });
  }

  static void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  static Future<void> queueAction(Map<String, dynamic> action) async {
    final existing = await _storage.read(key: AppConstants.pendingActionsKey);
    final actions = existing != null
        ? (jsonDecode(existing) as List<dynamic>).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
    actions.add(action);
    await _storage.write(
      key: AppConstants.pendingActionsKey,
      value: jsonEncode(actions),
    );
    onQueueChanged?.call();
  }

  static Future<List<Map<String, dynamic>>> getPendingActions() async {
    final existing = await _storage.read(key: AppConstants.pendingActionsKey);
    if (existing == null) return [];
    return (jsonDecode(existing) as List<dynamic>).cast<Map<String, dynamic>>();
  }

  static Future<int> getPendingCount() async {
    final actions = await getPendingActions();
    return actions.length;
  }

  static Future<void> syncPendingActions() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final actions = await getPendingActions();
      if (actions.isEmpty) {
        _isSyncing = false;
        return;
      }

      final remaining = <Map<String, dynamic>>[];
      for (final action in actions) {
        try {
          await _executeAction(action);
        } catch (_) {
          remaining.add(action);
        }
      }

      await _storage.write(
        key: AppConstants.pendingActionsKey,
        value: jsonEncode(remaining),
      );

      onSyncComplete?.call();
    } catch (_) {
    } finally {
      _isSyncing = false;
    }
  }

  static Future<void> _executeAction(Map<String, dynamic> action) async {
    final api = _api;
    if (api == null) return;
    final method = action['method'] as String;
    final endpoint = action['endpoint'] as String;
    final body = action['body'] as Map<String, dynamic>?;

    switch (method.toUpperCase()) {
      case 'POST':
        await api.post(endpoint, body: body);
      case 'PUT':
        await api.put(endpoint, body: body);
      default:
        await api.post(endpoint, body: body);
    }
  }

  static Future<void> clearPendingActions() async {
    await _storage.delete(key: AppConstants.pendingActionsKey);
    onQueueChanged?.call();
  }
}
