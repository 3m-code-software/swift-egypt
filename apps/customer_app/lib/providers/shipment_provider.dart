import 'package:flutter/foundation.dart';
import 'package:swift_egypt_shared/swift_egypt_shared.dart';
import '../services/api_service.dart';
import '../services/sync_service.dart';
import '../utils/error_handler.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String? type;
  final DateTime createdAt;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    this.body = '',
    this.type,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      body: json['message'] as String? ?? '',
      type: json['type'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      isRead: json['is_read'] as bool? ?? false,
    );
  }
}

class ShipmentProvider extends ChangeNotifier {
  final ApiService _api;
  List<Shipment> _shipments = [];
  Shipment? _selectedShipment;
  List<TrackingEvent> _trackingEvents = [];
  List<Document> _documents = [];
  List<Invoice> _invoices = [];
  List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  String? _error;
  String? _filterStatus;
  String? _filterServiceType;
  String _searchQuery = '';
  String _sortBy = 'newest';
  bool _showAdvancedFilters = false;

  ShipmentProvider(this._api);

  List<Shipment> get shipments => _filteredShipments;
  List<Shipment> get allShipments => _shipments;
  Shipment? get selectedShipment => _selectedShipment;
  List<TrackingEvent> get trackingEvents => _trackingEvents;
  List<Document> get documents => _documents;
  List<Invoice> get invoices => _invoices;
  List<NotificationItem> get notifications => _notifications;
  int get unreadNotificationCount =>
      _notifications.where((n) => !n.isRead).length;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get filterStatus => _filterStatus;
  String? get filterServiceType => _filterServiceType;
  String get searchQuery => _searchQuery;
  String get sortBy => _sortBy;
  bool get showAdvancedFilters => _showAdvancedFilters;

  List<Shipment> get _filteredShipments {
    var result = _shipments.toList();
    if (_filterStatus != null && _filterStatus != 'all') {
      if (_filterStatus == 'active') {
        result = result
            .where(
              (s) =>
                  s.status != ShipmentStatus.delivered &&
                  s.status != ShipmentStatus.cancelled &&
                  s.status != ShipmentStatus.returned,
            )
            .toList();
      } else if (_filterStatus == 'delivered') {
        result = result
            .where((s) => s.status == ShipmentStatus.delivered)
            .toList();
      } else if (_filterStatus == 'cancelled') {
        result = result
            .where((s) => s.status == ShipmentStatus.cancelled)
            .toList();
      }
    }
    if (_filterServiceType != null && _filterServiceType != 'all') {
      result = result
          .where((s) => s.serviceType.name == _filterServiceType)
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where(
            (s) =>
                s.trackingNumber.toLowerCase().contains(q) ||
                (s.senderName?.toLowerCase().contains(q) ?? false) ||
                (s.recipientName?.toLowerCase().contains(q) ?? false) ||
                s.pickupAddress.toLowerCase().contains(q) ||
                s.deliveryAddress.toLowerCase().contains(q),
          )
          .toList();
    }
    if (_sortBy == 'newest') {
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_sortBy == 'oldest') {
      result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    return result;
  }

  void setFilter(String? status) {
    _filterStatus = status;
    notifyListeners();
  }

  void setServiceTypeFilter(String? type) {
    _filterServiceType = type;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    notifyListeners();
  }

  void toggleAdvancedFilters() {
    _showAdvancedFilters = !_showAdvancedFilters;
    notifyListeners();
  }

  void clearAllFilters() {
    _filterStatus = null;
    _filterServiceType = null;
    _searchQuery = '';
    _sortBy = 'newest';
    notifyListeners();
  }

  Future<void> loadShipments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _api.get('/shipments');
      final data = response['data'];
      final items = data is List
          ? data
          : (response['items'] as List<dynamic>? ?? []);
      _shipments = items
          .map((e) => Shipment.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      _error = ErrorHandler.getMessage(e);
    } catch (e) {
      _error = ErrorHandler.getMessage(e);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadShipmentDetail(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _api.get('/shipments/$id');
      _selectedShipment = Shipment.fromJson(response);
      _trackingEvents = (response['tracking_events'] as List<dynamic>? ?? [])
          .map((e) => TrackingEvent.fromJson(e as Map<String, dynamic>))
          .toList();
      _loadDocuments(id);
    } on ApiException catch (e) {
      _error = ErrorHandler.getMessage(e);
    } catch (e) {
      _error = ErrorHandler.getMessage(e);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadDocuments(String shipmentId) async {
    try {
      final response = await _api.get('/documents/shipment/$shipmentId');
      final data = response['data'];
      _documents = (data is List ? data : [])
          .map((e) => Document.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _documents = [];
    }
  }

  Future<String?> createShipment(Map<String, dynamic> data) async {
    final connected = await SyncService.isConnected();
    if (!connected) {
      await SyncService.queueAction({
        'method': 'POST',
        'endpoint': '/shipments',
        'body': data,
      });
      return null;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _api.post('/shipments', body: data);
      final shipment = Shipment.fromJson(response);
      _shipments.insert(0, shipment);
      notifyListeners();
      return shipment.trackingNumber;
    } on ApiException catch (e) {
      _error = ErrorHandler.getMessage(e);
      notifyListeners();
      return null;
    } on NetworkException {
      _error = ErrorHandler.getMessage(NetworkException());
      notifyListeners();
      return null;
    } catch (e) {
      _error = ErrorHandler.getMessage(e);
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> estimatePrice(Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/pricing/estimate', body: data);
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<void> loadInvoices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _api.get('/invoices');
      final data = response['data'];
      final items = data is List
          ? data
          : (response['items'] as List<dynamic>? ?? []);
      _invoices = items
          .map((e) => Invoice.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      _error = ErrorHandler.getMessage(e);
    } catch (e) {
      _error = ErrorHandler.getMessage(e);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> uploadDocument(
    String shipmentId,
    String filePath,
    String docType,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.post(
        '/documents/upload',
        body: {
          'shipment_id': shipmentId,
          'document_type': docType,
          'file_name': filePath.split('/').last,
          'file_url': filePath,
          'file_size': 0,
        },
      );
      await loadShipmentDetail(shipmentId);
    } on ApiException catch (e) {
      _error = ErrorHandler.getMessage(e);
    } catch (e) {
      _error = ErrorHandler.getMessage(e);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadNotifications() async {
    try {
      final response = await _api.get('/notifications');
      final data = response['data'];
      final items = data is List ? data : [];
      _notifications = items
          .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markNotificationRead(String id) async {
    try {
      await _api.put('/notifications/$id/read');
      await loadNotifications();
    } catch (_) {}
  }

  Future<void> markAllNotificationsRead() async {
    try {
      await _api.put('/notifications/read-all');
      await loadNotifications();
    } catch (_) {}
  }

  void handleWebSocketMessage(Map<String, dynamic> msg) {
    final type = msg['type'] as String?;
    switch (type) {
      case 'new_notification':
        final data = msg['data'] as Map<String, dynamic>?;
        if (data != null) {
          _notifications.insert(0, NotificationItem.fromJson(data));
          notifyListeners();
        }
      case 'all_read':
        for (final n in _notifications) {
          n.isRead = true;
        }
        notifyListeners();
    }
  }

  void addRealtimeNotification(NotificationItem item) {
    _notifications.insert(0, item);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
