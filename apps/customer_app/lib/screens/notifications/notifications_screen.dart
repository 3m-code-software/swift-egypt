import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/routes.dart';
import '../../providers/shipment_provider.dart';
import '../../widgets/empty_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShipmentProvider>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ShipmentProvider>();
    final notifications = prov.notifications;
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () => prov.markAllNotificationsRead(),
              child: const Text('تحديد الكل كمقروء', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? const EmptyState(icon: Icons.notifications_off_outlined, title: 'لا توجد إشعارات', subtitle: 'ستظهر الإشعارات هنا عند تحديث شحناتك')
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              itemBuilder: (_, i) {
                final n = notifications[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  color: n.isRead ? null : AppTheme.primaryBlue.withValues(alpha: 0.05),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.15),
                      child: Icon(_iconForType(n.type), color: AppTheme.primaryBlue, size: 22),
                    ),
                    title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold, fontSize: 14)),
                    subtitle: Text(n.body, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)), maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: Text(_timeAgo(n.createdAt), style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                    onTap: () {
                      if (!n.isRead) {
                        prov.markNotificationRead(n.id);
                      }
                    },
                  ),
                );
              },
            ),
    );
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'shipment':
        return Icons.local_shipping;
      case 'invoice':
        return Icons.receipt_long;
      case 'document':
        return Icons.description;
      case 'alert':
        return Icons.warning_amber;
      default:
        return Icons.notifications;
    }
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} ي';
    return '${time.day}/${time.month}';
  }
}
