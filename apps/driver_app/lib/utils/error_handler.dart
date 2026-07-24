import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ErrorHandler {
  static String getMessage(Object error) {
    if (error is ApiError) {
      return _getApiMessage(error.statusCode, error.message);
    }
    final msg = error.toString();
    if (msg.contains('Network') || msg.contains('Socket') || msg.contains('Connection')) {
      return 'لا يوجد اتصال بالإنترنت. تحقق من اتصالك وحاول مرة أخرى.';
    }
    if (msg.contains('Timeout')) {
      return 'استغرق الاتصال وقتاً طويلاً. تحقق من سرعة الإنترنت وحاول مرة أخرى.';
    }
    return 'حدث خطأ غير متوقع. حاول مرة أخرى.';
  }

  static String _getApiMessage(int? statusCode, String originalMessage) {
    switch (statusCode) {
      case 400:
        return 'البيانات المرسلة غير صحيحة. تحقق من الإدخال وحاول مرة أخرى.';
      case 401:
        return 'بيانات الدخول غير صحيحة. تحقق من البريد الإلكتروني وكلمة المرور.';
      case 403:
        return 'ليس لديك صلاحية للوصول إلى هذا المحتوى.';
      case 404:
        return 'العنصر المطلوب غير موجود.';
      case 409:
        return 'يوجد تعارض. قد تكون العملية قد تمت بالفعل.';
      case 422:
        return 'البيانات المرسلة غير مكتملة. تحقق من جميع الحقول المطلوبة.';
      case 429:
        return 'عدد المحاولات تجاوز الحد المسموح. انتظر قليلاً وحاول مرة أخرى.';
      case 500:
        return 'حدث خطأ في الخادم. يرجى المحاولة لاحقاً.';
      case 502:
      case 503:
        return 'الخدمة غير متوفرة حالياً. يرجى المحاولة لاحقاً.';
      default:
        return originalMessage.isNotEmpty
            ? originalMessage
            : 'حدث خطأ ($statusCode). حاول مرة أخرى.';
    }
  }

  static String getAuthError(String? serverMessage) {
    if (serverMessage == null) return 'حدث خطأ غير متوقع. حاول مرة أخرى.';
    final msg = serverMessage.toLowerCase();
    if (msg.contains('invalid') || msg.contains('incorrect') || msg.contains('wrong')) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة. تحقق من بياناتك وحاول مرة أخرى.';
    }
    if (msg.contains('not found') || msg.contains('does not exist')) {
      return 'لا يوجد حساب مرتبط بهذا البريد الإلكتروني.';
    }
    if (msg.contains('locked') || msg.contains('disabled')) {
      return 'تم تعطيل الحساب مؤقتاً. تواصل مع المشرف.';
    }
    return serverMessage;
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'حسناً',
          textColor: Colors.white70,
          onPressed: () {},
        ),
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
