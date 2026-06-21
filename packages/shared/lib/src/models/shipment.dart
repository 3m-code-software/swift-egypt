import '../enums/shipment_status.dart';
import '../enums/service_type.dart';

class ShipmentItem {
  final String? id;
  final String description;
  final int quantity;
  final double weight;
  final double? length;
  final double? width;
  final double? height;
  final double? volumeWeight;

  ShipmentItem({
    this.id,
    required this.description,
    required this.quantity,
    required this.weight,
    this.length,
    this.width,
    this.height,
    this.volumeWeight,
  });

  factory ShipmentItem.fromJson(Map<String, dynamic> json) {
    return ShipmentItem(
      id: json['id'] as String?,
      description: json['description'] as String,
      quantity: json['quantity'] as int,
      weight: (json['weight'] as num).toDouble(),
      length: (json['length'] as num?)?.toDouble(),
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      volumeWeight: (json['volume_weight'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'quantity': quantity,
      'weight': weight,
      'length': length,
      'width': width,
      'height': height,
      'volume_weight': volumeWeight,
    };
  }
}

class Shipment {
  final String id;
  final String trackingNumber;
  final ServiceType serviceType;
  final ShipmentStatus status;
  final String? customerId;
  final String? driverId;
  final String? vehicleId;
  final String? containerId;
  final String? voyageId;
  final String? branchId;
  final String pickupAddress;
  final String deliveryAddress;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final String? senderName;
  final String? senderPhone;
  final String? recipientName;
  final String? recipientPhone;
  final double? estimatedPrice;
  final double? finalPrice;
  final String? notes;
  final List<ShipmentItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  Shipment({
    required this.id,
    required this.trackingNumber,
    required this.serviceType,
    required this.status,
    this.customerId,
    this.driverId,
    this.vehicleId,
    this.containerId,
    this.voyageId,
    this.branchId,
    required this.pickupAddress,
    required this.deliveryAddress,
    this.pickupLatitude,
    this.pickupLongitude,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.senderName,
    this.senderPhone,
    this.recipientName,
    this.recipientPhone,
    this.estimatedPrice,
    this.finalPrice,
    this.notes,
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Shipment.fromJson(Map<String, dynamic> json) {
    return Shipment(
      id: json['id'] as String,
      trackingNumber: json['tracking_number'] as String,
      serviceType: ServiceType.fromApi(json['service_type'] as String),
      status: ShipmentStatus.fromApi(json['status'] as String),
      customerId: json['customer_id'] as String?,
      driverId: json['driver_id'] as String?,
      vehicleId: json['vehicle_id'] as String?,
      containerId: json['container_id'] as String?,
      voyageId: json['voyage_id'] as String?,
      branchId: json['branch_id'] as String?,
      pickupAddress: json['pickup_address'] as String,
      deliveryAddress: json['delivery_address'] as String,
      pickupLatitude: (json['pickup_latitude'] as num?)?.toDouble(),
      pickupLongitude: (json['pickup_longitude'] as num?)?.toDouble(),
      deliveryLatitude: (json['delivery_latitude'] as num?)?.toDouble(),
      deliveryLongitude: (json['delivery_longitude'] as num?)?.toDouble(),
      senderName: json['sender_name'] as String?,
      senderPhone: json['sender_phone'] as String?,
      recipientName: json['recipient_name'] as String?,
      recipientPhone: json['recipient_phone'] as String?,
      estimatedPrice: (json['estimated_price'] as num?)?.toDouble(),
      finalPrice: (json['final_price'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => ShipmentItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tracking_number': trackingNumber,
      'service_type': serviceType.apiValue,
      'status': status.apiValue,
      'customer_id': customerId,
      'driver_id': driverId,
      'vehicle_id': vehicleId,
      'container_id': containerId,
      'voyage_id': voyageId,
      'branch_id': branchId,
      'pickup_address': pickupAddress,
      'delivery_address': deliveryAddress,
      'pickup_latitude': pickupLatitude,
      'pickup_longitude': pickupLongitude,
      'delivery_latitude': deliveryLatitude,
      'delivery_longitude': deliveryLongitude,
      'sender_name': senderName,
      'sender_phone': senderPhone,
      'recipient_name': recipientName,
      'recipient_phone': recipientPhone,
      'estimated_price': estimatedPrice,
      'final_price': finalPrice,
      'notes': notes,
      'items': items.map((e) => e.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
