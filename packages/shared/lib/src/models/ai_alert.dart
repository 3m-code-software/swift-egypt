class AiAlert {
  final String id;
  final String? shipmentId;
  final String alertType;
  final String severity;
  final String title;
  final String description;
  final Map<String, dynamic>? metadata;
  final bool isRead;
  final DateTime createdAt;

  AiAlert({
    required this.id,
    this.shipmentId,
    required this.alertType,
    required this.severity,
    required this.title,
    required this.description,
    this.metadata,
    required this.isRead,
    required this.createdAt,
  });

  factory AiAlert.fromJson(Map<String, dynamic> json) {
    return AiAlert(
      id: json['id'] as String,
      shipmentId: json['shipment_id'] as String?,
      alertType: json['alert_type'] as String,
      severity: json['severity'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shipment_id': shipmentId,
      'alert_type': alertType,
      'severity': severity,
      'title': title,
      'description': description,
      'metadata': metadata,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
