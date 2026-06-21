import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin _notifPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initializeBackgroundService() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  await _notifPlugin.initialize(
    const InitializationSettings(android: androidSettings),
  );
}

Future<void> showLocationNotification() async {
  const androidDetails = AndroidNotificationDetails(
    'location_service',
    'خدمة الموقع',
    channelDescription: 'إشعار دائم لتتبع موقع السائق',
    importance: Importance.low,
    priority: Priority.low,
    ongoing: true,
    autoCancel: false,
    showWhen: false,
  );
  await _notifPlugin.show(
    888,
    'Swift Egypt',
    'تتبع الموقع نشط',
    const NotificationDetails(android: androidDetails),
  );
}

Future<void> cancelLocationNotification() async {
  await _notifPlugin.cancel(888);
}
