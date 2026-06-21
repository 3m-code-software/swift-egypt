class SupportTicket {
  final String id;
  final String? customerId;
  final String? shipmentId;
  final String subject;
  final String message;
  final String status;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  SupportTicket({
    required this.id,
    this.customerId,
    this.shipmentId,
    required this.subject,
    required this.message,
    required this.status,
    this.assignedTo,
    required this.createdAt,
    this.resolvedAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] as String,
      customerId: json['customer_id'] as String?,
      shipmentId: json['shipment_id'] as String?,
      subject: json['subject'] as String,
      message: json['message'] as String,
      status: json['status'] as String,
      assignedTo: json['assigned_to'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'shipment_id': shipmentId,
      'subject': subject,
      'message': message,
      'status': status,
      'assigned_to': assignedTo,
      'created_at': createdAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }
}
