class ProofOfDelivery {
  final String id;
  final String shipmentId;
  final String? signatureUrl;
  final String? photoUrl;
  final double? latitude;
  final double? longitude;
  final String? recipientName;
  final String? notes;
  final String? driverId;
  final DateTime deliveredAt;

  ProofOfDelivery({
    required this.id,
    required this.shipmentId,
    this.signatureUrl,
    this.photoUrl,
    this.latitude,
    this.longitude,
    this.recipientName,
    this.notes,
    this.driverId,
    required this.deliveredAt,
  });

  factory ProofOfDelivery.fromJson(Map<String, dynamic> json) {
    return ProofOfDelivery(
      id: json['id'] as String,
      shipmentId: json['shipment_id'] as String,
      signatureUrl: json['signature_url'] as String?,
      photoUrl: json['photo_url'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      recipientName: json['recipient_name'] as String?,
      notes: json['notes'] as String?,
      driverId: json['driver_id'] as String?,
      deliveredAt: DateTime.parse(json['delivered_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shipment_id': shipmentId,
      'signature_url': signatureUrl,
      'photo_url': photoUrl,
      'latitude': latitude,
      'longitude': longitude,
      'recipient_name': recipientName,
      'notes': notes,
      'driver_id': driverId,
      'delivered_at': deliveredAt.toIso8601String(),
    };
  }
}
