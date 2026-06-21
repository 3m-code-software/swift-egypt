import 'notification_service.dart';

Future<void> initializeBackgroundService() async {
}

Future<void> showLocationNotification() async {
  await NotificationService().showNotification(
    id: 888,
    title: 'Swift Egypt',
    body: 'تتبع الموقع نشط',
    ongoing: true,
  );
}

Future<void> cancelLocationNotification() async {
  await NotificationService().cancelNotification(888);
}
