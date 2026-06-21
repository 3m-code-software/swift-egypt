import 'package:intl/intl.dart';

class DateFormatter {
  static String format(DateTime date, {String locale = 'ar'}) {
    final formatter = DateFormat('yyyy/MM/dd', locale);
    return formatter.format(date);
  }

  static String formatWithTime(DateTime date, {String locale = 'ar'}) {
    final formatter = DateFormat('yyyy/MM/dd HH:mm', locale);
    return formatter.format(date);
  }

  static String relativeTime(DateTime date, {String locale = 'ar'}) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (locale == 'ar') {
      if (diff.inMinutes < 1) return 'الآن';
      if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
      if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
      if (diff.inDays < 30) return 'منذ ${diff.inDays} يوم';
      return format(date);
    } else {
      if (diff.inMinutes < 1) return 'now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      if (diff.inDays < 30) return '${diff.inDays} days ago';
      return format(date, locale: 'en');
    }
  }
}
