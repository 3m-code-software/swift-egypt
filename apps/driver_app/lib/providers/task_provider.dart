import 'package:flutter/foundation.dart';
import 'package:swift_egypt_shared/swift_egypt_shared.dart';
import '../services/api_service.dart';
import '../services/sync_service.dart';

class TaskProvider extends ChangeNotifier {
  List<Shipment> _tasks = [];
  Shipment? _selectedTask;
  bool _isLoading = false;
  String? _error;

  List<Shipment> get tasks => _tasks;
  Shipment? get selectedTask => _selectedTask;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Shipment> get pendingTasks =>
      _tasks.where((t) => t.status == ShipmentStatus.confirmed).toList();

  List<Shipment> get inProgressTasks => _tasks
      .where((t) =>
          t.status == ShipmentStatus.pickedUp ||
          t.status == ShipmentStatus.outForDelivery)
      .toList();

  List<Shipment> get completedTasks =>
      _tasks.where((t) => t.status == ShipmentStatus.delivered).toList();

  int get totalCount => _tasks.length;
  int get completedCount => completedTasks.length;
  int get pendingCount => pendingTasks.length;

  Future<void> loadTodayTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/drivers/tasks/today');
      final data = response['data'];
      final list = data is List
          ? data
              .map((e) =>
                  Shipment.fromJson(e as Map<String, dynamic>))
              .toList()
          : <Shipment>[];
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

  Future<void> loadTaskDetail(String shipmentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/shipments/$shipmentId');
      _selectedTask = Shipment.fromJson(response);
    } on ApiError catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'حدث خطأ في تحميل تفاصيل الشحنة';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
    required String shipmentId,
    required String status,
    Map<String, dynamic>? extraData,
  }) async {
    final endpoint = '/drivers/tasks/$shipmentId/status';
    final body = {
      'status': status,
      ...?extraData,
    };
    if (await _queueOrCall(method: 'POST', endpoint: endpoint, body: body)) {
      return true;
    }
    try {
      await ApiService.post(endpoint, body: body);
      await loadTodayTasks();
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

  Future<bool> submitProofOfDelivery({
    required String shipmentId,
    required String recipientName,
    String? photoPath,
    String? signaturePath,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    final endpoint = '/drivers/tasks/$shipmentId/proof-of-delivery';
    final body = {
      'recipient_name': recipientName,
      'photo_path': photoPath,
      'signature_path': signaturePath,
      'latitude': latitude,
      'longitude': longitude,
      'notes': notes,
    };
    if (await _queueOrCall(method: 'POST', endpoint: endpoint, body: body)) {
      return true;
    }
    try {
      await ApiService.post(endpoint, body: body);
      await loadTodayTasks();
      return true;
    } on ApiError catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'حدث خطأ في إرسال إثبات التسليم';
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitProofOfPickup({
    required String shipmentId,
    required int itemCount,
    String? photoPath,
    String? signaturePath,
    String? notes,
  }) async {
    final endpoint = '/drivers/tasks/$shipmentId/proof-of-pickup';
    final body = {
      'item_count': itemCount,
      'photo_path': photoPath,
      'signature_path': signaturePath,
      'notes': notes,
    };
    if (await _queueOrCall(method: 'POST', endpoint: endpoint, body: body)) {
      return true;
    }
    try {
      await ApiService.post(endpoint, body: body);
      await loadTodayTasks();
      return true;
    } on ApiError catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'حدث خطأ في إرسال إثبات الاستلام';
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitCollection({
    required String shipmentId,
    required double amount,
    required String paymentMethod,
  }) async {
    final endpoint = '/drivers/tasks/$shipmentId/collection';
    final body = {
      'amount': amount,
      'payment_method': paymentMethod,
    };
    if (await _queueOrCall(method: 'POST', endpoint: endpoint, body: body)) {
      return true;
    }
    try {
      await ApiService.post(endpoint, body: body);
      await loadTodayTasks();
      return true;
    } on ApiError catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'حدث خطأ في إرسال التحصيل';
      notifyListeners();
      return false;
    }
  }

  Future<List<Shipment>> getCompletedTasks({
    DateTime? fromDate,
    DateTime? toDate,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (fromDate != null) queryParams['from'] = fromDate.toIso8601String();
      if (toDate != null) queryParams['to'] = toDate.toIso8601String();
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      final response = await ApiService.get(
        '/drivers/tasks/completed',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );
      final data = response['data'];
      return data is List
          ? data
              .map((e) =>
                  Shipment.fromJson(e as Map<String, dynamic>))
              .toList()
          : <Shipment>[];
    } catch (e) {
      _error = 'حدث خطأ في تحميل المهام المكتملة';
      notifyListeners();
      return [];
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
