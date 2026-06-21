enum ShipmentStatus {
  draft,
  pendingReview,
  confirmed,
  pickedUp,
  atOriginWarehouse,
  inTransit,
  atPortBorder,
  customsClearance,
  outForDelivery,
  delivered,
  returned,
  cancelled,
  onHold;

  String get apiValue {
    switch (this) {
      case ShipmentStatus.draft:
        return 'draft';
      case ShipmentStatus.pendingReview:
        return 'pending_review';
      case ShipmentStatus.confirmed:
        return 'confirmed';
      case ShipmentStatus.pickedUp:
        return 'picked_up';
      case ShipmentStatus.atOriginWarehouse:
        return 'at_origin_warehouse';
      case ShipmentStatus.inTransit:
        return 'in_transit';
      case ShipmentStatus.atPortBorder:
        return 'at_port_border';
      case ShipmentStatus.customsClearance:
        return 'customs_clearance';
      case ShipmentStatus.outForDelivery:
        return 'out_for_delivery';
      case ShipmentStatus.delivered:
        return 'delivered';
      case ShipmentStatus.returned:
        return 'returned';
      case ShipmentStatus.cancelled:
        return 'cancelled';
      case ShipmentStatus.onHold:
        return 'on_hold';
    }
  }

  static ShipmentStatus fromApi(String value) {
    switch (value) {
      case 'draft':
        return ShipmentStatus.draft;
      case 'pending_review':
        return ShipmentStatus.pendingReview;
      case 'confirmed':
        return ShipmentStatus.confirmed;
      case 'picked_up':
        return ShipmentStatus.pickedUp;
      case 'at_origin_warehouse':
        return ShipmentStatus.atOriginWarehouse;
      case 'in_transit':
        return ShipmentStatus.inTransit;
      case 'at_port_border':
        return ShipmentStatus.atPortBorder;
      case 'customs_clearance':
        return ShipmentStatus.customsClearance;
      case 'out_for_delivery':
        return ShipmentStatus.outForDelivery;
      case 'delivered':
        return ShipmentStatus.delivered;
      case 'returned':
        return ShipmentStatus.returned;
      case 'cancelled':
        return ShipmentStatus.cancelled;
      case 'on_hold':
        return ShipmentStatus.onHold;
      default:
        return ShipmentStatus.draft;
    }
  }

  String get displayName {
    switch (this) {
      case ShipmentStatus.draft:
        return 'مسودة';
      case ShipmentStatus.pendingReview:
        return 'قيد المراجعة';
      case ShipmentStatus.confirmed:
        return 'تم التأكيد';
      case ShipmentStatus.pickedUp:
        return 'تم الاستلام';
      case ShipmentStatus.atOriginWarehouse:
        return 'في المستودع';
      case ShipmentStatus.inTransit:
        return 'في الطريق';
      case ShipmentStatus.atPortBorder:
        return 'في الميناء/المنفذ';
      case ShipmentStatus.customsClearance:
        return 'في التخليص';
      case ShipmentStatus.outForDelivery:
        return 'خارج للتسليم';
      case ShipmentStatus.delivered:
        return 'تم التسليم';
      case ShipmentStatus.returned:
        return 'مرتجع';
      case ShipmentStatus.cancelled:
        return 'ملغي';
      case ShipmentStatus.onHold:
        return 'معلق';
    }
  }

  String get displayNameEn {
    switch (this) {
      case ShipmentStatus.draft:
        return 'Draft';
      case ShipmentStatus.pendingReview:
        return 'Pending Review';
      case ShipmentStatus.confirmed:
        return 'Confirmed';
      case ShipmentStatus.pickedUp:
        return 'Picked Up';
      case ShipmentStatus.atOriginWarehouse:
        return 'At Warehouse';
      case ShipmentStatus.inTransit:
        return 'In Transit';
      case ShipmentStatus.atPortBorder:
        return 'At Port/Border';
      case ShipmentStatus.customsClearance:
        return 'Customs Clearance';
      case ShipmentStatus.outForDelivery:
        return 'Out for Delivery';
      case ShipmentStatus.delivered:
        return 'Delivered';
      case ShipmentStatus.returned:
        return 'Returned';
      case ShipmentStatus.cancelled:
        return 'Cancelled';
      case ShipmentStatus.onHold:
        return 'On Hold';
    }
  }
}
