import '../enums/order_status.dart';

class BatchOrder {
  final String id;
  final String batchId;
  final String? batchNumber;
  final String customerName;
  final String? customerPhone;
  final String? customerPhone2;
  final String? address;
  final String? province;
  final String? city;
  final String? productName;
  final int quantity;
  final double productPrice;
  final double shippingCost;
  final double total;
  final String? notes;
  final OrderStatus status;
  final String? deliveryNotes;
  final String? returnedReason;
  final double? collectedAmount;
  final int? callAttempts;
  final int? deliveredQuantity;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime? assignedAt;

  BatchOrder({
    required this.id,
    required this.batchId,
    this.batchNumber,
    required this.customerName,
    this.customerPhone,
    this.customerPhone2,
    this.address,
    this.province,
    this.city,
    this.productName,
    required this.quantity,
    required this.productPrice,
    required this.shippingCost,
    required this.total,
    this.notes,
    required this.status,
    this.deliveryNotes,
    this.returnedReason,
    this.collectedAmount,
    this.callAttempts,
    this.deliveredQuantity,
    this.latitude,
    this.longitude,
    required this.createdAt,
    this.assignedAt,
  });

  factory BatchOrder.fromJson(Map<String, dynamic> json) {
    return BatchOrder(
      id: json['id'] as String,
      batchId: json['batch_id'] as String,
      batchNumber: json['batch_number'] as String?,
      customerName: json['customer_name'] as String? ?? '',
      customerPhone: json['customer_phone'] as String?,
      customerPhone2: json['customer_phone2'] as String?,
      address: json['address'] as String?,
      province: json['province'] as String?,
      city: json['city'] as String?,
      productName: json['product_name'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      productPrice: (json['product_price'] as num?)?.toDouble() ?? 0.0,
      shippingCost: (json['shipping_cost'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      status: OrderStatus.fromString(json['status'] as String? ?? 'pending'),
      deliveryNotes: json['delivery_notes'] as String?,
      returnedReason: json['returned_reason'] as String?,
      collectedAmount: (json['collected_amount'] as num?)?.toDouble(),
      callAttempts: (json['call_attempts'] as num?)?.toInt(),
      deliveredQuantity: (json['delivered_quantity'] as num?)?.toInt(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      assignedAt: json['assigned_at'] != null
          ? DateTime.parse(json['assigned_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batch_id': batchId,
      'batch_number': batchNumber,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_phone2': customerPhone2,
      'address': address,
      'province': province,
      'city': city,
      'product_name': productName,
      'quantity': quantity,
      'product_price': productPrice,
      'shipping_cost': shippingCost,
      'total': total,
      'notes': notes,
      'status': status.value,
      'delivery_notes': deliveryNotes,
      'returned_reason': returnedReason,
      'collected_amount': collectedAmount,
      'call_attempts': callAttempts,
      'delivered_quantity': deliveredQuantity,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
      'assigned_at': assignedAt?.toIso8601String(),
    };
  }
}
