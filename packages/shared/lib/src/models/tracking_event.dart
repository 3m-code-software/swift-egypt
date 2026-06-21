import '../enums/shipment_status.dart';
import '../enums/tracking_event_type.dart';

class TrackingEvent {
  final String id;
  final String shipmentId;
  final TrackingEventType eventType;
  final ShipmentStatus? newStatus;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? description;
  final String? userId;
  final DateTime createdAt;

  TrackingEvent({
    required this.id,
    required this.shipmentId,
    required this.eventType,
    this.newStatus,
    this.location,
    this.latitude,
    this.longitude,
    this.description,
    this.userId,
    required this.createdAt,
  });

  factory TrackingEvent.fromJson(Map<String, dynamic> json) {
    return TrackingEvent(
      id: json['id'] as String,
      shipmentId: json['shipment_id'] as String,
      eventType: TrackingEventType.fromApi(json['event_type'] as String),
      newStatus: json['new_status'] != null
          ? ShipmentStatus.fromApi(json['new_status'] as String)
          : null,
      location: json['location'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      description: json['description'] as String?,
      userId: json['user_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shipment_id': shipmentId,
      'event_type': eventType.apiValue,
      'new_status': newStatus?.apiValue,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
