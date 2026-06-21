import 'package:flutter/material.dart';
import 'package:swift_egypt_shared/swift_egypt_shared.dart';
import '../core/theme.dart';

class ShipmentCard extends StatelessWidget {
  final Shipment shipment;
  final VoidCallback? onTap;

  const ShipmentCard({super.key, required this.shipment, this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColors = {
      ShipmentStatus.delivered: AppTheme.accentGreen,
      ShipmentStatus.cancelled: AppTheme.errorRed,
      ShipmentStatus.inTransit: AppTheme.primaryBlue,
      ShipmentStatus.outForDelivery: AppTheme.warningAmber,
      ShipmentStatus.pickedUp: AppTheme.secondaryTeal,
    };

    final color = statusColors[shipment.status] ?? AppTheme.primaryBlue;
    final serviceIcons = {
      ServiceType.internationalRoad: Icons.local_shipping,
      ServiceType.maritime: Icons.directions_boat,
      ServiceType.domestic: Icons.local_shipping,
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(serviceIcons[shipment.serviceType] ?? Icons.local_shipping, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shipment.trackingNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(shipment.serviceType.displayName, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(shipment.status.displayName, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${shipment.createdAt.toString().substring(0, 10)}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}
