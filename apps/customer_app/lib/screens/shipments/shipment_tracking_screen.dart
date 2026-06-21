import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:swift_egypt_shared/swift_egypt_shared.dart';
import '../../core/theme.dart';
import '../../providers/shipment_provider.dart';
import '../../widgets/tracking_map.dart';
import '../../widgets/status_timeline.dart';
import '../../widgets/loading_widget.dart';

class ShipmentTrackingScreen extends StatefulWidget {
  final String shipmentId;
  const ShipmentTrackingScreen({super.key, required this.shipmentId});

  @override
  State<ShipmentTrackingScreen> createState() => _ShipmentTrackingScreenState();
}

class _ShipmentTrackingScreenState extends State<ShipmentTrackingScreen> {
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
    final shipment = prov.selectedShipment;

    return Scaffold(
      appBar: AppBar(title: const Text('تتبع الشحنة'), actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: shipment != null
              ? () {
                  Clipboard.setData(ClipboardData(text: shipment.trackingNumber));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم نسخ رقم التتبع للمشاركة')),
                  );
                }
              : null,
        ),
      ]),
      body: prov.isLoading
          ? const LoadingWidget(message: 'جاري تحميل بيانات التتبع...')
          : shipment == null
              ? const Center(child: Text('لا توجد بيانات تتبع'))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      if (shipment.pickupLatitude != null && shipment.deliveryLatitude != null)
                        SizedBox(
                          height: 280,
                          child: TrackingMap(
                            pickupLat: shipment.pickupLatitude!,
                            pickupLng: shipment.pickupLongitude!,
                            deliveryLat: shipment.deliveryLatitude!,
                            deliveryLng: shipment.deliveryLongitude!,
                            currentLat: prov.trackingEvents.isNotEmpty
                                ? prov.trackingEvents.last.latitude
                                : null,
                            currentLng: prov.trackingEvents.isNotEmpty
                                ? prov.trackingEvents.last.longitude
                                : null,
                          ),
                        )
                      else
                        Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.map_outlined, size: 48, color: Color(0xFF94A3B8)),
                                SizedBox(height: 8),
                                Text('الخريطة غير متوفرة', style: TextStyle(color: Color(0xFF94A3B8))),
                              ],
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text(shipment.trackingNumber,
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: shipment.status == ShipmentStatus.delivered
                                        ? AppTheme.accentGreen.withValues(alpha: 0.15)
                                        : AppTheme.primaryBlue.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    shipment.status.displayName,
                                    style: TextStyle(
                                      color: shipment.status == ShipmentStatus.delivered
                                          ? AppTheme.accentGreen
                                          : AppTheme.primaryBlue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (prov.trackingEvents.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    'آخر تحديث: ${prov.trackingEvents.last.createdAt.toString().substring(0, 16)}',
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                  ),
                                ],
                                if (prov.trackingEvents.isNotEmpty &&
                                    prov.trackingEvents.last.location != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.location_on, size: 16, color: AppTheme.primaryBlue),
                                      const SizedBox(width: 4),
                                      Text(prov.trackingEvents.last.location!,
                                          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (prov.trackingEvents.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('أحداث التتبع',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              StatusTimeline(events: prov.trackingEvents),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }
}
