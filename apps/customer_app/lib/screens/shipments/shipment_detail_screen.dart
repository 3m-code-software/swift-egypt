import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:swift_egypt_shared/swift_egypt_shared.dart';
import '../../core/theme.dart';
import '../../core/routes.dart';
import '../../providers/shipment_provider.dart';
import '../../widgets/status_timeline.dart';
import '../../widgets/loading_widget.dart';

class ShipmentDetailScreen extends StatefulWidget {
  final String shipmentId;
  const ShipmentDetailScreen({super.key, required this.shipmentId});

  @override
  State<ShipmentDetailScreen> createState() => _ShipmentDetailScreenState();
}

class _ShipmentDetailScreenState extends State<ShipmentDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShipmentProvider>().loadShipmentDetail(widget.shipmentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ShipmentProvider>();

    if (prov.isLoading && prov.selectedShipment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الشحنة')),
        body: const LoadingWidget(message: 'جاري تحميل التفاصيل...'),
      );
    }

    final shipment = prov.selectedShipment;
    if (shipment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الشحنة')),
        body: const Center(child: Text('لم يتم العثور على الشحنة')),
      );
    }

    final statusColors = {
      ShipmentStatus.delivered: AppTheme.accentGreen,
      ShipmentStatus.cancelled: AppTheme.errorRed,
      ShipmentStatus.inTransit: AppTheme.primaryBlue,
      ShipmentStatus.outForDelivery: AppTheme.warningAmber,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الشحنة')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(shipment.serviceType.displayName, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: (statusColors[shipment.status] ?? AppTheme.primaryBlue).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            shipment.status.displayName,
                            style: TextStyle(
                              color: statusColors[shipment.status] ?? AppTheme.primaryBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(shipment.trackingNumber, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: shipment.trackingNumber));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ رقم التتبع')));
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('نسخ رقم التتبع'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (prov.trackingEvents.isNotEmpty) ...[
              const Text('التتبع', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              StatusTimeline(events: prov.trackingEvents),
              const SizedBox(height: 16),
            ],
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('معلومات الشحنة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const Divider(),
                    _infoRow('المرسل', '${shipment.senderName ?? ''}\n${shipment.senderPhone ?? ''}'),
                    _infoRow('عنوان الاستلام', shipment.pickupAddress),
                    const Divider(),
                    _infoRow('المستلم', '${shipment.recipientName ?? ''}\n${shipment.recipientPhone ?? ''}'),
                    _infoRow('عنوان التسليم', shipment.deliveryAddress),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('تفاصيل الطرد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const Divider(),
                    ...shipment.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.description, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text('الكمية: ${item.quantity} | الوزن: ${item.weight} كجم'),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
            if (shipment.estimatedPrice != null || shipment.finalPrice != null) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('السعر', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Divider(),
                      if (shipment.estimatedPrice != null)
                        _infoRow('السعر التقديري', '${shipment.estimatedPrice!.toStringAsFixed(2)} ج.م'),
                      if (shipment.finalPrice != null)
                        _infoRow('السعر النهائي', '${shipment.finalPrice!.toStringAsFixed(2)} ج.م', bold: true),
                    ],
                  ),
                ),
              ),
            ],
            if (prov.documents.isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('المستندات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Divider(),
                      ...prov.documents.map((doc) => ListTile(
                            leading: const Icon(Icons.description_outlined),
                            title: Text(doc.fileName),
                            trailing: const Icon(Icons.chevron_left),
                          )),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.tracking, arguments: shipment.trackingNumber),
                icon: const Icon(Icons.near_me),
                label: const Text('تتبع الشحنة'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
