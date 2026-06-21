import 'package:flutter/material.dart';
import 'package:swift_egypt_shared/swift_egypt_shared.dart';
import '../core/theme.dart';

class ServiceTypeCard extends StatelessWidget {
  final ServiceType serviceType;
  final IconData icon;
  final VoidCallback onTap;

  const ServiceTypeCard({
    super.key,
    required this.serviceType,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gradients = {
      ServiceType.internationalRoad: [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
      ServiceType.maritime: [const Color(0xFF0D9488), const Color(0xFF0F766E)],
      ServiceType.domestic: [const Color(0xFF16A34A), const Color(0xFF15803D)],
    };

    final colors = gradients[serviceType]!;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors[0].withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              serviceType.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
