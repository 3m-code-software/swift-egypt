class Branch {
  final String id;
  final String name;
  final String nameAr;
  final String? address;
  final String? phone;
  final String? managerId;
  final double? latitude;
  final double? longitude;
  final bool isActive;
  final DateTime createdAt;

  Branch({
    required this.id,
    required this.name,
    required this.nameAr,
    this.address,
    this.phone,
    this.managerId,
    this.latitude,
    this.longitude,
    required this.isActive,
    required this.createdAt,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'] as String,
      name: json['name'] as String,
      nameAr: json['name_ar'] as String,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      managerId: json['manager_id'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_ar': nameAr,
      'address': address,
      'phone': phone,
      'manager_id': managerId,
      'latitude': latitude,
      'longitude': longitude,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
