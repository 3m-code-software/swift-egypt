import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(initSettings);

    const androidChannel = AndroidNotificationChannel(
      'swift_customer_channel',
      'إشعارات الطلبات',
      description: 'إشعارات الطلبات والشحنات',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  Future<void> showNotification(
    int id,
    String title,
    String body, {
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'swift_customer_channel',
      'إشعارات الطلبات',
      channelDescription: 'إشعارات الطلبات والشحنات',
      importance: Importance.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _plugin.show(id, title, body, details, payload: payload);
  }

  Future<void> showShipmentStatusChanged(
      String trackingNumber, String status) async {
    await showNotification(
      trackingNumber.hashCode,
      'تحديث حالة الشحنة',
      'تم تحديث حالة الشحنة $trackingNumber إلى: $status',
    );
  }

  Future<void> showPaymentConfirmed(double amount) async {
    await showNotification(
      amount.toInt(),
      'تأكيد الدفع',
      'تم تأكيد الدفع بقيمة $amount جنيه',
    );
  }
}
