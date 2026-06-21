import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swift_egypt_shared/swift_egypt_shared.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../providers/task_provider.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/loading_overlay.dart';

class TaskDetailScreen extends StatefulWidget {
  final String shipmentId;

  const TaskDetailScreen({super.key, required this.shipmentId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTaskDetail(widget.shipmentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final shipment = taskProvider.selectedTask;

    return Scaffold(
      appBar: AppBar(
        title: Text(shipment?.trackingNumber ?? 'تفاصيل الشحنة'),
      ),
      body: taskProvider.isLoading
          ? const LoadingOverlay()
          : shipment == null
              ? Center(
                  child: Text(
                    taskProvider.error ?? 'لا توجد بيانات',
                    style: const TextStyle(color: AppTheme.errorRed),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(shipment),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        'معلومات العميل',
                        Icons.person_rounded,
                        [
                          _infoRow(
                            'المرسل',
                            shipment.senderName ?? '---',
                            shipment.senderPhone,
                          ),
                          _infoRow(
                            'المستلم',
                            shipment.recipientName ?? '---',
                            shipment.recipientPhone,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildAddressCard(shipment),
                      const SizedBox(height: 12),
                      if (shipment.items.isNotEmpty)
                        _buildItemsCard(shipment.items),
                      const SizedBox(height: 12),
                      _buildPriceCard(shipment),
                      const SizedBox(height: 12),
                      _buildActions(shipment),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader(Shipment shipment) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'رقم التتبع',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                StatusBadge(status: shipment.status),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    shipment.trackingNumber,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.primaryBlue,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat('yyyy/MM/dd HH:mm').format(shipment.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, List<Widget> rows) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryBlue, size: 20),
                const SizedBox(width: 8),
                Text(title,
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, String? subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey)),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
          if (subtitle != null)
            InkWell(
              onTap: () => _makePhoneCall(subtitle),
              child: Row(
                children: [
                  const Icon(Icons.phone_rounded,
                      size: 14, color: AppTheme.primaryBlue),
                  const SizedBox(width: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(Shipment shipment) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    color: AppTheme.accentGreen, size: 20),
                const SizedBox(width: 8),
                Text('العنوان', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.trip_origin,
                    color: AppTheme.accentGreen, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('من:',
                          style: Theme.of(context).textTheme.bodySmall),
                      Text(shipment.pickupAddress),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.flag_rounded,
                    color: AppTheme.errorRed, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('إلى:',
                          style: Theme.of(context).textTheme.bodySmall),
                      Text(shipment.deliveryAddress),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (shipment.deliveryLatitude != null &&
                shipment.deliveryLongitude != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openNavigation(shipment),
                  icon: const Icon(Icons.navigation_rounded),
                  label: const Text('فتح في الخريطة'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard(List<ShipmentItem> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.inventory_rounded,
                    color: AppTheme.primaryBlue, size: 20),
                const SizedBox(width: 8),
                Text('المواد', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.description,
                                style: Theme.of(context).textTheme.bodyLarge),
                            if (item.weight > 0)
                              Text('الوزن: ${item.weight} كجم',
                                  style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '× ${item.quantity}',
                          style: const TextStyle(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCard(Shipment shipment) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('السعر', style: Theme.of(context).textTheme.titleMedium),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (shipment.estimatedPrice != null)
                  Text(
                    '${shipment.estimatedPrice!.toStringAsFixed(2)} ج.م',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.accentGreen,
                        ),
                  ),
                if (shipment.finalPrice != null)
                  Text(
                    'السعر النهائي: ${shipment.finalPrice!.toStringAsFixed(2)} ج.م',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(Shipment shipment) {
    final status = shipment.status;

    List<Widget> buttons = [];

    if (status == ShipmentStatus.confirmed) {
      buttons.add(_actionButton(
        'بدء المهمة',
        Icons.play_arrow_rounded,
        AppTheme.accentGreen,
        () => _updateStatus(shipment.id, 'picked_up'),
      ));
    }

    if (status == ShipmentStatus.pickedUp) {
      buttons.add(_actionButton(
        'تسليم للشحن',
        Icons.local_shipping_rounded,
        AppTheme.primaryBlue,
        () => _updateStatus(shipment.id, 'out_for_delivery'),
      ));
    }

    if (status == ShipmentStatus.outForDelivery) {
      buttons.add(_actionButton(
        'تم التسليم',
        Icons.check_circle_rounded,
        AppTheme.accentGreen,
        () {
          Navigator.of(context).pushNamed(
            '/delivery/proof',
            arguments: shipment.id,
          );
        },
      ));
    }

    if (status == ShipmentStatus.delivered) {
      buttons.add(
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.check_circle,
                    color: AppTheme.accentGreen, size: 24),
                const SizedBox(width: 12),
                Text('تم التسليم بنجاح',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.accentGreen,
                        )),
              ],
            ),
          ),
        ),
      );
    }

    if (shipment.deliveryLatitude != null &&
        shipment.deliveryLongitude != null) {
      buttons.add(_actionButton(
        '导航',
        Icons.navigation_rounded,
        AppTheme.primaryBlue,
        () => _openNavigation(shipment),
        isOutlined: true,
      ));
    }

    return Column(children: buttons);
  }

  Widget _actionButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed, {
    bool isOutlined = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: isOutlined
          ? OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(text),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color),
              ),
            )
          : ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(text),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
              ),
            ),
    );
  }

  Future<void> _updateStatus(String shipmentId, String status) async {
    final provider = context.read<TaskProvider>();
    final success = await provider.updateTaskStatus(
      shipmentId: shipmentId,
      status: status,
    );
    if (success && mounted) {
      provider.loadTaskDetail(shipmentId);
    }
  }

  void _openNavigation(Shipment shipment) {
    Navigator.of(context).pushNamed(
      '/task/navigation',
      arguments: {
        'pickupLat': shipment.pickupLatitude ?? 0.0,
        'pickupLng': shipment.pickupLongitude ?? 0.0,
        'deliveryLat': shipment.deliveryLatitude ?? 0.0,
        'deliveryLng': shipment.deliveryLongitude ?? 0.0,
        'destinationName': shipment.deliveryAddress,
        'recipientPhone': shipment.recipientPhone,
      },
    );
  }

  void _makePhoneCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('لا يمكن الاتصال بـ $phone')),
        );
      }
    }
  }
}
