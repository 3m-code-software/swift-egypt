import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../services/location_service.dart';

class TaskNavigationScreen extends StatefulWidget {
  final double pickupLat;
  final double pickupLng;
  final double deliveryLat;
  final double deliveryLng;
  final String destinationName;
  final String? recipientPhone;

  const TaskNavigationScreen({
    super.key,
    required this.pickupLat,
    required this.pickupLng,
    required this.deliveryLat,
    required this.deliveryLng,
    required this.destinationName,
    this.recipientPhone,
  });

  @override
  State<TaskNavigationScreen> createState() => _TaskNavigationScreenState();
}

class _TaskNavigationScreenState extends State<TaskNavigationScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Position? _currentPosition;
  String _eta = '--';
  double _distance = 0;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final position = await LocationService.getCurrentPosition();
    if (position != null && mounted) {
      setState(() {
        _currentPosition = position;
        _updateMarkers();
        _calculateDistance();
      });
    }
  }

  void _updateMarkers() {
    final markers = <Marker>{};

    if (_currentPosition != null) {
      markers.add(Marker(
        markerId: const MarkerId('current'),
        position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'موقعك الحالي'),
      ));
    }

    markers.add(Marker(
      markerId: const MarkerId('delivery'),
      position: LatLng(widget.deliveryLat, widget.deliveryLng),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(title: widget.destinationName),
    ));

    if (widget.pickupLat != 0 && widget.pickupLng != 0) {
      markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(widget.pickupLat, widget.pickupLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: 'موقع الاستلام'),
      ));
    }

    setState(() => _markers = markers);
  }

  void _calculateDistance() {
    if (_currentPosition != null) {
      _distance = LocationService.calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        widget.deliveryLat,
        widget.deliveryLng,
      );
      final distanceKm = (_distance / 1000);
      final speedKmh = 40.0;
      final etaMinutes = (distanceKm / speedKmh * 60).round();
      _eta = etaMinutes < 60 ? '$etaMinutes دقيقة' : '${(etaMinutes / 60).round()} ساعة';
    }
  }

  void _openGoogleMaps() async {
    final url = 'https://www.google.com/maps/dir/?api=1'
        '&destination=${widget.deliveryLat},${widget.deliveryLng}'
        '&travelmode=driving';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكن فتح خرائط جوجل')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملاحة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_rounded),
            onPressed: widget.recipientPhone != null
                ? () async {
                    final uri = Uri.parse('tel:${widget.recipientPhone}');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('لا يمكن الاتصال بـ ${widget.recipientPhone}')),
                      );
                    }
                  }
                : null,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildInfoBar(),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.deliveryLat, widget.deliveryLng),
                zoom: 12,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onMapCreated: (controller) => _mapController = controller,
              zoomControlsEnabled: true,
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildInfoBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.destinationName,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.timer_rounded,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('الوصول المتوقع: $_eta',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  (_distance / 1000).toStringAsFixed(1),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryBlue,
                      ),
                ),
                Text('كم',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.primaryBlue)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton.icon(
          onPressed: _openGoogleMaps,
          icon: const Icon(Icons.map_rounded),
          label: const Text('فتح في خرائط جوجل'),
        ),
      ),
    );
  }
}
