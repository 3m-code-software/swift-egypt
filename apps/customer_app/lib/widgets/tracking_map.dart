import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../core/theme.dart';

class TrackingMap extends StatelessWidget {
  final double pickupLat;
  final double pickupLng;
  final double deliveryLat;
  final double deliveryLng;
  final double? currentLat;
  final double? currentLng;

  const TrackingMap({
    super.key,
    required this.pickupLat,
    required this.pickupLng,
    required this.deliveryLat,
    required this.deliveryLng,
    this.currentLat,
    this.currentLng,
  });

  @override
  Widget build(BuildContext context) {
    if (pickupLat == 0 && deliveryLat == 0) {
      return _placeholder();
    }
    return SizedBox(
      height: 250,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(
            currentLat ?? (pickupLat + deliveryLat) / 2,
            currentLng ?? (pickupLng + deliveryLng) / 2,
          ),
          zoom: 12,
        ),
        markers: {
          if (pickupLat != 0)
            Marker(
              markerId: const MarkerId('pickup'),
              position: LatLng(pickupLat, pickupLng),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
              infoWindow: const InfoWindow(title: 'موقع الاستلام'),
            ),
          if (deliveryLat != 0)
            Marker(
              markerId: const MarkerId('delivery'),
              position: LatLng(deliveryLat, deliveryLng),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              infoWindow: const InfoWindow(title: 'موقع التسليم'),
            ),
          if (currentLat != null && currentLng != null)
            Marker(
              markerId: const MarkerId('current'),
              position: LatLng(currentLat!, currentLng!),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
              infoWindow: const InfoWindow(title: 'الموقع الحالي'),
            ),
        },
        myLocationEnabled: currentLat != null,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(0),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 48, color: Color(0xFF94A3B8)),
            SizedBox(height: 8),
            Text('خريطة التتبع', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }
}
