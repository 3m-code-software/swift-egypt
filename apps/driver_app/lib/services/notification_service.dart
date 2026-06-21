import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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

    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          'swift_driver_channel',
          'مهام التوصيل',
          description: 'إشعارات المهام والتوصيل',
          importance: Importance.high,
        ),
      );
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool ongoing = false,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'swift_driver_channel',
      'مهام التوصيل',
      channelDescription: 'إشعارات المهام والتوصيل',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: ongoing,
      autoCancel: !ongoing,
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _plugin.show(id, title, body, details, payload: payload);
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> showTaskAssigned(String orderId, String customerName) async {
    await showNotification(
      id: orderId.hashCode,
      title: 'مهمة جديدة',
      body: 'توصيل لـ $customerName',
      payload: orderId,
    );
  }

  Future<void> showTaskStatusUpdated(String orderId, String status) async {
    await showNotification(
      id: orderId.hashCode,
      title: 'تحديث الحالة',
      body: 'تم تحديث حالة الطلب إلى: $status',
      payload: orderId,
    );
  }

  Future<void> showEndOfDay() async {
    await showNotification(
      id: 9999,
      title: 'إنهاء اليوم',
      body: 'تم إنهاء اليوم بنجاح',
    );
  }
}
