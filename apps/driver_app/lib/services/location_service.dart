import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'api_service.dart';
import 'sync_service.dart';
import 'background_service.dart';

class LocationService {
  static Position? _currentPosition;
  static StreamSubscription<Position>? _positionSubscription;
  static bool _isUpdating = false;
  static DateTime _lastSent = DateTime.now();
  static const Duration _minInterval = Duration(seconds: 120);

  static Future<void> initialize() async {
  }

  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      await Permission.locationAlways.request();
    }
    return status.isGranted;
  }

  static Future<Position?> getCurrentPosition() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return _currentPosition;
    } catch (e) {
      return null;
    }
  }

  static Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      return null;
    }
  }

  static void startBackgroundUpdates() {
    if (_isUpdating) return;
    _isUpdating = true;
    _lastSent = DateTime.now();
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 50,
            timeLimit: null,
          ),
        ).listen((position) async {
          _currentPosition = position;
          if (DateTime.now().difference(_lastSent) < _minInterval) return;
          _lastSent = DateTime.now();
          await _sendLocation(position.latitude, position.longitude);
        });
    showLocationNotification();
  }

  static void stopBackgroundUpdates() {
    _isUpdating = false;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    cancelLocationNotification();
  }

  static Future<void> sendCurrentLocation() async {
    final position = _currentPosition;
    if (position == null) {
      final pos = await getCurrentPosition();
      if (pos == null) return;
      await _sendLocation(pos.latitude, pos.longitude);
    } else {
      await _sendLocation(position.latitude, position.longitude);
    }
  }

  static Future<void> _sendLocation(double lat, double lng) async {
    try {
      final body = {
        'latitude': lat,
        'longitude': lng,
        'timestamp': DateTime.now().toIso8601String(),
      };
      if (!await SyncService.isConnected()) {
        await SyncService.queueAction({
          'method': 'POST',
          'endpoint': '/drivers/location',
          'body': body,
        });
        return;
      }
      await ApiService.post('/drivers/location', body: body);
    } catch (_) {}
  }

  static double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }
}
