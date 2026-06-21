import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/sync_provider.dart';
import '../../services/location_service.dart';
import '../../widgets/offline_banner.dart';
import '../tasks/task_list_screen.dart';
import '../activity/activity_log_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _screens = const [
    _HomeTab(),
    TaskListScreen(),
    ActivityLogScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTodayTasks();
      context.read<TaskProvider>().loadStats();
    });
    LocationService.startBackgroundUpdates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: _screens[_currentIndex]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_rounded), label: 'المهام'),
          BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'النشاط'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'الملف الشخصي'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final syncProvider = context.watch<SyncProvider>();
    final driverName = auth.user?.fullName ?? 'السائق';
    final stats = taskProvider.stats;
    final batchIds = taskProvider.tasks.map((t) => t.batchId).toSet().toList();

    return RefreshIndicator(
      onRefresh: () async {
        await taskProvider.loadTodayTasks();
        await taskProvider.loadStats();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.primaryBlue,
                  child: Text(
                    driverName.isNotEmpty ? driverName[0].toUpperCase() : 'S',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مرحباً بك،',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      ),
                      Text(driverName, style: Theme.of(context).textTheme.titleLarge),
                    ],
                  ),
                ),
                if (syncProvider.hasPending)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.warningOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: GestureDetector(
                      onTap: () => syncProvider.triggerSync(),
                      child: syncProvider.isSyncing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.warningOrange,
                              ),
                            )
                          : const Icon(Icons.sync, color: AppTheme.warningOrange),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text('ملخص اليوم', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _StatCard(
                  label: 'تم التوصيل',
                  value: '${stats['delivered'] ?? 0}',
                  icon: Icons.check_circle_rounded,
                  color: AppTheme.accentGreen,
                )),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(
                  label: 'معلق',
                  value: '${stats['pending'] ?? 0}',
                  icon: Icons.pending_actions_rounded,
                  color: AppTheme.warningOrange,
                )),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _StatCard(
                  label: 'مرتجع',
                  value: '${stats['returned'] ?? 0}',
                  icon: Icons.replay_rounded,
                  color: AppTheme.errorRed,
                )),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(
                  label: 'لا رد',
                  value: '${stats['no_answer'] ?? 0}',
                  icon: Icons.phone_missed_rounded,
                  color: Colors.grey,
                )),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _StatCard(
                  label: 'توصيل جزئي',
                  value: '${stats['partial'] ?? 0}',
                  icon: Icons.remove_circle_outline_rounded,
                  color: AppTheme.primaryLight,
                )),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(
                  label: 'إجمالي',
                  value: '${stats['total'] ?? 0}',
                  icon: Icons.assignment_rounded,
                  color: AppTheme.primaryBlue,
                )),
              ],
            ),
            const SizedBox(height: 24),
            Text('إجراءات سريعة', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _QuickActionCard(
                  icon: Icons.assignment_rounded,
                  label: 'عرض المهام',
                  color: AppTheme.primaryBlue,
                  onTap: () => Navigator.of(context).pushNamed('/tasks'),
                )),
                const SizedBox(width: 12),
                Expanded(child: _QuickActionCard(
                  icon: Icons.person_pin_rounded,
                  label: 'الملف الشخصي',
                  color: AppTheme.accentGreen,
                  onTap: () => Navigator.of(context).pushNamed('/profile'),
                )),
              ],
            ),
            if (batchIds.length == 1) ...[
              const SizedBox(height: 12),
              _QuickActionCard(
                icon: Icons.today_rounded,
                label: 'إنهاء اليوم',
                color: AppTheme.warningOrange,
                onTap: () => _confirmEndOfDay(context, batchIds.first),
              ),
            ],
            const SizedBox(height: 12),
            _QuickActionCard(
              icon: Icons.auto_awesome_rounded,
              label: 'Swift AI',
              color: AppTheme.primaryBlue,
              onTap: () => Navigator.of(context).pushNamed('/ai-chat'),
            ),
            const SizedBox(height: 24),
            if (taskProvider.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
            if (taskProvider.error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    taskProvider.error!,
                    style: const TextStyle(color: AppTheme.errorRed),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmEndOfDay(BuildContext context, String batchId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إنهاء اليوم'),
        content: const Text(
          'سيتم تحويل جميع الطلبات المعلقة إلى مرتجعة. هل أنت متأكد؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<TaskProvider>().submitEndOfDay(batchId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningOrange,
            ),
            child: const Text('تأكيد إنهاء اليوم'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, color: color, size: 40),
              const SizedBox(height: 8),
              Text(label,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
