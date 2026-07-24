import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'package:swift_egypt_shared/swift_egypt_shared.dart';

class ErrorHandler {
  static String getMessage(Object error) {
    if (error is NetworkException) {
      return 'لا يوجد اتصال بالإنترنت. تحقق من اتصالك وحاول مرة أخرى.';
    }
    if (error is UnauthorizedException) {
      return 'انتهت صلاحية جلستك. يرجى تسجيل الدخول مرة أخرى.';
    }
    if (error is NotFoundException) {
      return 'العنصر المطلوب غير موجود أو تم حذفه.';
    }
    if (error is ValidationException) {
      return _parseValidationErrors(error.errors) ?? error.message;
    }
    if (error is ApiException) {
      return _getApiMessage(error.statusCode, error.message);
    }
    return 'حدث خطأ غير متوقع. حاول مرة أخرى.';
  }

  static String _getApiMessage(int statusCode, String originalMessage) {
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

  static String? _parseValidationErrors(Map<String, dynamic>? errors) {
    if (errors == null || errors.isEmpty) return null;
    final messages = <String>[];
    errors.forEach((field, value) {
      if (value is List) {
        messages.addAll(value.map((e) => e.toString()));
      } else {
        messages.add(value.toString());
      }
    });
    return messages.isNotEmpty ? messages.first : null;
  }

  static String getAuthError(String? serverMessage) {
    if (serverMessage == null) return 'حدث خطأ غير متوقع. حاول مرة أخرى.';
    final msg = serverMessage.toLowerCase();
    if (msg.contains('invalid') || msg.contains('incorrect') || msg.contains('wrong')) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة. تحقق من بياناتك وحاول مرة أخرى.';
    }
    if (msg.contains('not found') || msg.contains('does not exist')) {
      return 'لا يوجد حساب مرتبط بهذا البريد الإلكتروني. سجّل حساب جديد أولاً.';
    }
    if (msg.contains('already') || msg.contains('exists')) {
      return 'هذا البريد الإلكتروني مسجّل بالفعل. سجّل دخولك أو استخدم بريداً آخر.';
    }
    if (msg.contains('password')) {
      return 'كلمة المرور غير مطابقة. تأكد من إدخال كلمة المرور الصحيحة.';
    }
    if (msg.contains('locked') || msg.contains('disabled')) {
      return 'تم تعطيل الحساب مؤقتاً. تواصل مع الدعم الفني.';
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
              child: Text(
                message,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.errorRed,
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
              child: Text(
                message,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showWarningSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.warningAmber,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
