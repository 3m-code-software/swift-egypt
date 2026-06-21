import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final user = auth.user;
    final driverName = user?.fullName ?? 'سائق';
    final email = user?.email ?? '---';
    final phone = user?.phone ?? '---';

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryBlue,
              child: Text(
                driverName.isNotEmpty ? driverName[0].toUpperCase() : 'S',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(driverName,
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(phone,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    )),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('إحصائيات اليوم',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statItem(context, 'مكتملة',
                            '${taskProvider.completedCount}', AppTheme.accentGreen),
                        _statItem(context, 'معلقة',
                            '${taskProvider.pendingCount}', AppTheme.warningOrange),
                        _statItem(context, 'إجمالي',
                            '${taskProvider.totalCount}', AppTheme.primaryBlue),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  _profileTile(context, Icons.person_rounded, 'الاسم', driverName),
                  _profileTile(context, Icons.email_rounded, 'البريد الإلكتروني', email),
                  _profileTile(context, Icons.phone_rounded, 'رقم الهاتف', phone),
                  _profileTile(context, Icons.badge_rounded, 'الدور', 'سائق'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.language_rounded,
                        color: AppTheme.primaryBlue),
                    title: const Text('اللغة'),
                    subtitle: const Text('العربية'),
                    trailing: const Icon(Icons.chevron_left_rounded),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('سيتم إضافة تغيير اللغة قريباً')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.notifications_rounded,
                        color: AppTheme.primaryBlue),
                    title: const Text('الإشعارات'),
                    subtitle: const Text('مفعلة'),
                    trailing: Switch(
                      value: true,
                      activeColor: AppTheme.accentGreen,
                      onChanged: (_) {},
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showLogoutDialog(context),
                icon: const Icon(Icons.logout_rounded,
                    color: AppTheme.errorRed),
                label: const Text('تسجيل الخروج',
                    style: TextStyle(color: AppTheme.errorRed)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.errorRed),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _statItem(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            )),
        const SizedBox(height: 4),
        Text(label,
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _profileTile(
      BuildContext context, IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryBlue),
      title: Text(value),
      subtitle: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthProvider>().logout();
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: const Text('تسجيل الخروج',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
