enum OrderStatus {
  pending,
  approved,
  delivered,
  partial,
  returned,
  noAnswer;

  static OrderStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return OrderStatus.pending;
      case 'approved':
        return OrderStatus.approved;
      case 'delivered':
        return OrderStatus.delivered;
      case 'partial':
        return OrderStatus.partial;
      case 'returned':
        return OrderStatus.returned;
      case 'no_answer':
        return OrderStatus.noAnswer;
      default:
        return OrderStatus.pending;
    }
  }

  String get value {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.approved:
        return 'approved';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.partial:
        return 'partial';
      case OrderStatus.returned:
        return 'returned';
      case OrderStatus.noAnswer:
        return 'no_answer';
    }
  }

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'معلق';
      case OrderStatus.approved:
        return 'تمت الموافقة';
      case OrderStatus.delivered:
        return 'تم التوصيل';
      case OrderStatus.partial:
        return 'توصيل جزئي';
      case OrderStatus.returned:
        return 'مرتجع';
      case OrderStatus.noAnswer:
        return 'لا رد';
    }
  }
}
