class Driver {
  final String id;
  final String userId;
  final String? fullName;
  final String? phone;
  final String? email;
  final String? branchId;
  final String? vehicleId;
  final bool isAvailable;
  final double? currentLatitude;
  final double? currentLongitude;
  final DateTime? lastLocationUpdate;
  final DateTime createdAt;

  Driver({
    required this.id,
    required this.userId,
    this.fullName,
    this.phone,
    this.email,
    this.branchId,
    this.vehicleId,
    required this.isAvailable,
    this.currentLatitude,
    this.currentLongitude,
    this.lastLocationUpdate,
    required this.createdAt,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      branchId: json['branch_id'] as String?,
      vehicleId: json['vehicle_id'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
      currentLatitude: (json['current_latitude'] as num?)?.toDouble(),
      currentLongitude: (json['current_longitude'] as num?)?.toDouble(),
      lastLocationUpdate: json['last_location_update'] != null
          ? DateTime.parse(json['last_location_update'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'branch_id': branchId,
      'vehicle_id': vehicleId,
      'is_available': isAvailable,
      'current_latitude': currentLatitude,
      'current_longitude': currentLongitude,
      'last_location_update': lastLocationUpdate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
