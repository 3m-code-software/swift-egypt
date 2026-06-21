import 'package:flutter/foundation.dart';
import 'package:swift_egypt_shared/swift_egypt_shared.dart';
import '../services/api_service.dart';
import '../services/sync_service.dart';

class TaskProvider extends ChangeNotifier {
  List<BatchOrder> _tasks = [];
  BatchOrder? _selectedTask;
  Map<String, int> _stats = {};
  bool _isLoading = false;
  String? _error;

  List<BatchOrder> get tasks => _tasks;
  BatchOrder? get selectedTask => _selectedTask;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, int> get stats => _stats;

  List<BatchOrder> get pendingTasks =>
      _tasks.where((t) => t.status == OrderStatus.pending).toList();

  List<BatchOrder> get inProgressTasks =>
      _tasks.where((t) => t.status == OrderStatus.approved).toList();

  List<BatchOrder> get completedTasks => _tasks
      .where((t) =>
          t.status == OrderStatus.delivered ||
          t.status == OrderStatus.partial ||
          t.status == OrderStatus.returned ||
          t.status == OrderStatus.noAnswer)
      .toList();

  List<BatchOrder> get deliveryTasks =>
      _tasks.where((t) => t.status == OrderStatus.pending).toList();

  int get totalCount => _tasks.length;
  int get completedCount => completedTasks.length;
  int get pendingCount => pendingTasks.length;

  Future<void> loadTodayTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/agent/tasks');
      final data = response['data'] ?? response;
      final list = data is List
          ? data
              .map((e) =>
                  BatchOrder.fromJson(e as Map<String, dynamic>))
              .toList()
          : <BatchOrder>[];
      _tasks = list;
    } on ApiError catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'حدث خطأ في تحميل المهام';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTaskDetail(String orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final existing = _tasks.where((t) => t.id == orderId).toList();
      if (existing.isNotEmpty) {
        _selectedTask = existing.first;
      } else {
        final response = await ApiService.get('/agent/tasks');
        final data = response['data'] ?? response;
        final orders = data is List
            ? data
                .map((e) =>
                    BatchOrder.fromJson(e as Map<String, dynamic>))
                .toList()
            : <BatchOrder>[];
        _selectedTask = orders.where((t) => t.id == orderId).firstOrNull;
      }
    } on ApiError catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'حدث خطأ في تحميل تفاصيل الطلب';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStats() async {
    try {
      final response = await ApiService.get('/agent/tasks/stats');
      final data = response['data'] ?? response;
      if (data is Map) {
        _stats = data.map((k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0));
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> _queueOrCall({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
  }) async {
    if (!await SyncService.isConnected()) {
      await SyncService.queueAction({
        'method': method,
        'endpoint': endpoint,
        'body': body,
      });
      return true;
    }
    return false;
  }

  Future<bool> updateTaskStatus({
    required String orderId,
    required String status,
    String? deliveryNotes,
    String? returnedReason,
    double? collectedAmount,
    int? deliveredQuantity,
    double? latitude,
    double? longitude,
  }) async {
    final endpoint = '/agent/tasks/$orderId/status';
    final body = <String, dynamic>{
      'status': status,
    };
    if (deliveryNotes != null) body['delivery_notes'] = deliveryNotes;
    if (returnedReason != null) body['returned_reason'] = returnedReason;
    if (collectedAmount != null) body['collected_amount'] = collectedAmount;
    if (deliveredQuantity != null) body['delivered_quantity'] = deliveredQuantity;
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;

    if (await _queueOrCall(method: 'PUT', endpoint: endpoint, body: body)) {
      return true;
    }
    try {
      await ApiService.put(endpoint, body: body);
      await loadTodayTasks();
      await loadStats();
      return true;
    } on ApiError catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'حدث خطأ في تحديث الحالة';
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitEndOfDay(String batchId) async {
    final endpoint = '/agent/batches/$batchId/end-day';
    if (await _queueOrCall(method: 'POST', endpoint: endpoint)) {
      return true;
    }
    try {
      await ApiService.post(endpoint);
      await loadTodayTasks();
      return true;
    } on ApiError catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'حدث خطأ في إنهاء اليوم';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
