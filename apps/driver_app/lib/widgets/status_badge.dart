import 'package:flutter/material.dart';
import 'package:swift_egypt_shared/swift_egypt_shared.dart';
import '../core/theme.dart';

class StatusBadge extends StatelessWidget {
  final ShipmentStatus status;
  final bool small;

  const StatusBadge({super.key, required this.status, this.small = false});

  Color get _color {
    switch (status) {
      case ShipmentStatus.delivered:
        return AppTheme.accentGreen;
      case ShipmentStatus.outForDelivery:
      case ShipmentStatus.pickedUp:
        return AppTheme.primaryBlue;
      case ShipmentStatus.confirmed:
      case ShipmentStatus.inTransit:
        return AppTheme.warningOrange;
      case ShipmentStatus.cancelled:
      case ShipmentStatus.returned:
        return AppTheme.errorRed;
      case ShipmentStatus.onHold:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color get _bgColor => _color.withValues(alpha: 0.1);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 12,
        vertical: small ? 3 : 6,
      ),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: small ? 6 : 8,
            height: small ? 6 : 8,
            decoration: BoxDecoration(
              color: _color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: small ? 4 : 6),
          Text(
            status.displayName,
            style: TextStyle(
              color: _color,
              fontSize: small ? 11 : 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
