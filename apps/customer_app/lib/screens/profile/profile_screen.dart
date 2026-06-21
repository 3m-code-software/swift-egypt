import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/routes.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final localeProv = context.watch<LocaleProvider>();
    final user = auth.user;

    void confirmLogout() {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تسجيل الخروج'),
          content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                auth.logout();
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
              child: const Text('تسجيل الخروج'),
            ),
          ],
        ),
      );
    }

    void confirmDelete() {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('حذف الحساب'),
          content: const Text('هل أنت متأكد؟ هذا الإجراء لا يمكن التراجع عنه. سيتم حذف جميع بياناتك.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
              child: const Text('حذف الحساب'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('الملف الشخصي')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 48,
              backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.15),
              child: Text(
                (user?.fullName ?? 'U').substring(0, 1).toUpperCase(),
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
              ),
            ),
            const SizedBox(height: 12),
            Text(user?.fullName ?? 'مستخدم', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(user?.email ?? '', style: const TextStyle(color: Color(0xFF64748B))),
            if (user?.phone != null) Text(user!.phone!, style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 24),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit_outlined, color: AppTheme.primaryBlue),
                    title: const Text('تعديل الملف الشخصي'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.location_on_outlined, color: AppTheme.primaryBlue),
                    title: const Text('العناوين المحفوظة'),
                    subtitle: const Text('3 عناوين مسجلة'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.receipt_long_outlined, color: AppTheme.primaryBlue),
                    title: const Text('الفواتير'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.invoices),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.headset_mic_outlined, color: AppTheme.primaryBlue),
                    title: const Text('الدعم الفني'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.support),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('اللغة / Language'),
                    subtitle: Text(localeProv.locale == 'ar' ? 'العربية' : 'English'),
                    value: localeProv.locale == 'en',
                    onChanged: (_) => localeProv.toggleLocale(),
                    secondary: const Icon(Icons.language, color: AppTheme.primaryBlue),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('الوضع الليلي'),
                    subtitle: Text(localeProv.isDark ? 'مفعل' : 'غير مفعل'),
                    value: localeProv.isDark,
                    onChanged: (_) => localeProv.toggleTheme(),
                    secondary: const Icon(Icons.dark_mode, color: AppTheme.primaryBlue),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline, color: AppTheme.primaryBlue),
                    title: const Text('إصدار التطبيق'),
                    subtitle: const Text(AppConstants.appVersion),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: confirmLogout,
                icon: const Icon(Icons.logout, color: AppTheme.errorRed),
                label: const Text('تسجيل الخروج', style: TextStyle(color: AppTheme.errorRed)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.errorRed)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: confirmDelete,
              child: const Text('حذف الحساب', style: TextStyle(color: AppTheme.errorRed)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
