class Vehicle {
  final String id;
  final String plateNumber;
  final String model;
  final String type;
  final double? maxWeight;
  final double? maxVolume;
  final String? branchId;
  final bool isAvailable;
  final DateTime createdAt;

  Vehicle({
    required this.id,
    required this.plateNumber,
    required this.model,
    required this.type,
    this.maxWeight,
    this.maxVolume,
    this.branchId,
    required this.isAvailable,
    required this.createdAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String,
      plateNumber: json['plate_number'] as String,
      model: json['model'] as String,
      type: json['type'] as String,
      maxWeight: (json['max_weight'] as num?)?.toDouble(),
      maxVolume: (json['max_volume'] as num?)?.toDouble(),
      branchId: json['branch_id'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plate_number': plateNumber,
      'model': model,
      'type': type,
      'max_weight': maxWeight,
      'max_volume': maxVolume,
      'branch_id': branchId,
      'is_available': isAvailable,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
