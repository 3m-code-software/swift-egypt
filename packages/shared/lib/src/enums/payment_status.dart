enum PaymentStatus {
  pending,
  partiallyPaid,
  paid,
  refunded,
  cancelled;

  String get apiValue => name;

  static PaymentStatus fromApi(String value) {
    return PaymentStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'قيد الانتظار';
      case PaymentStatus.partiallyPaid:
        return 'مدفوع جزئياً';
      case PaymentStatus.paid:
        return 'مدفوع بالكامل';
      case PaymentStatus.refunded:
        return 'مسترجع';
      case PaymentStatus.cancelled:
        return 'ملغي';
    }
  }
}
