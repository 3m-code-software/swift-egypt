import '../enums/payment_status.dart';

class Invoice {
  final String id;
  final String shipmentId;
  final String invoiceNumber;
  final double subtotal;
  final double? tax;
  final double? insurance;
  final double? additionalFees;
  final double total;
  final PaymentStatus paymentStatus;
  final String? notes;
  final DateTime createdAt;
  final DateTime? paidAt;

  Invoice({
    required this.id,
    required this.shipmentId,
    required this.invoiceNumber,
    required this.subtotal,
    this.tax,
    this.insurance,
    this.additionalFees,
    required this.total,
    required this.paymentStatus,
    this.notes,
    required this.createdAt,
    this.paidAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as String,
      shipmentId: json['shipment_id'] as String,
      invoiceNumber: json['invoice_number'] as String,
      subtotal: (json['subtotal'] as num).toDouble(),
      tax: (json['tax'] as num?)?.toDouble(),
      insurance: (json['insurance'] as num?)?.toDouble(),
      additionalFees: (json['additional_fees'] as num?)?.toDouble(),
      total: (json['total'] as num).toDouble(),
      paymentStatus: PaymentStatus.fromApi(json['payment_status'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shipment_id': shipmentId,
      'invoice_number': invoiceNumber,
      'subtotal': subtotal,
      'tax': tax,
      'insurance': insurance,
      'additional_fees': additionalFees,
      'total': total,
      'payment_status': paymentStatus.apiValue,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
    };
  }
}
