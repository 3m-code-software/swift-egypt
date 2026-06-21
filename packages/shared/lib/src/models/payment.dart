import '../enums/payment_status.dart';

class Payment {
  final String id;
  final String? invoiceId;
  final String? shipmentId;
  final double amount;
  final String paymentMethod;
  final PaymentStatus status;
  final String? transactionId;
  final String? collectedBy;
  final DateTime createdAt;

  Payment({
    required this.id,
    this.invoiceId,
    this.shipmentId,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    this.transactionId,
    this.collectedBy,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      invoiceId: json['invoice_id'] as String?,
      shipmentId: json['shipment_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String,
      status: PaymentStatus.fromApi(json['status'] as String),
      transactionId: json['transaction_id'] as String?,
      collectedBy: json['collected_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'shipment_id': shipmentId,
      'amount': amount,
      'payment_method': paymentMethod,
      'status': status.apiValue,
      'transaction_id': transactionId,
      'collected_by': collectedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
