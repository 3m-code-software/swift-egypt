enum UserRole {
  customer,
  driver,
  operations,
  branchManager,
  finance,
  admin;

  String get apiValue {
    switch (this) {
      case UserRole.customer:
        return 'customer';
      case UserRole.driver:
        return 'driver';
      case UserRole.operations:
        return 'operations';
      case UserRole.branchManager:
        return 'branch_manager';
      case UserRole.finance:
        return 'finance';
      case UserRole.admin:
        return 'admin';
    }
  }

  static UserRole fromApi(String value) {
    switch (value) {
      case 'customer':
        return UserRole.customer;
      case 'driver':
        return UserRole.driver;
      case 'operations':
        return UserRole.operations;
      case 'branch_manager':
        return UserRole.branchManager;
      case 'finance':
        return UserRole.finance;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.customer;
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.customer:
        return 'عميل';
      case UserRole.driver:
        return 'سائق';
      case UserRole.operations:
        return 'عمليات';
      case UserRole.branchManager:
        return 'مدير فرع';
      case UserRole.finance:
        return 'مالية';
      case UserRole.admin:
        return 'مدير النظام';
    }
  }
}
