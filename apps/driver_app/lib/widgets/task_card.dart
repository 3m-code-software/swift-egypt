import 'package:flutter/material.dart';
import 'package:swift_egypt_shared/swift_egypt_shared.dart';
import '../core/theme.dart';
import 'status_badge.dart';

class TaskCard extends StatelessWidget {
  final BatchOrder order;
  final VoidCallback? onTap;

  const TaskCard({super.key, required this.order, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      order.customerName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  StatusBadge(status: order.status, small: true),
                ],
              ),
              const SizedBox(height: 8),
              if (order.customerPhone != null)
                Row(
                  children: [
                    const Icon(Icons.phone_rounded, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      order.customerPhone!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.primaryBlue,
                          ),
                    ),
                  ],
                ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_rounded, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.address ?? '---',
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (order.productName != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${order.quantity} × ${order.productName}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  Text(
                    '${order.total.toStringAsFixed(0)} ج.م',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.accentGreen,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
