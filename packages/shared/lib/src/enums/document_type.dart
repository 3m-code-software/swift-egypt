enum DocumentType {
  invoice,
  waybill,
  commercialRegister,
  passport,
  packingList,
  certificateOfOrigin,
  insurance,
  other;

  String get apiValue => name;

  static DocumentType fromApi(String value) {
    return DocumentType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DocumentType.other,
    );
  }

  String get displayName {
    switch (this) {
      case DocumentType.invoice:
        return 'فاتورة';
      case DocumentType.waybill:
        return 'بوليصة شحن';
      case DocumentType.commercialRegister:
        return 'سجل تجاري';
      case DocumentType.passport:
        return 'جواز سفر';
      case DocumentType.packingList:
        return 'قائمة التعبئة';
      case DocumentType.certificateOfOrigin:
        return 'شهادة منشأ';
      case DocumentType.insurance:
        return 'وثيقة تأمين';
      case DocumentType.other:
        return 'أخرى';
    }
  }
}
