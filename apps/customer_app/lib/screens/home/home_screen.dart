import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swift_egypt_shared/swift_egypt_shared.dart';
import '../../core/theme.dart';
import '../../core/routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shipment_provider.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/service_type_card.dart';
import '../../widgets/shipment_card.dart';
import '../../widgets/offline_banner.dart';
import '../shipments/shipment_list_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _HomeTab(),
    ShipmentListScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'الشحنات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            label: 'الإشعارات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            label: 'الملف الشخصي',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShipmentProvider>().loadShipments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final shipmentProv = context.watch<ShipmentProvider>();
    final userName = auth.user?.fullName ?? 'عميلنا العزيز';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_shipping, size: 28),
            const SizedBox(width: 8),
            const Text('Swift Egypt'),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.notifications),
              ),
              if (shipmentProv.unreadNotificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.errorRed,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '${shipmentProv.unreadNotificationCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => shipmentProv.loadShipments(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحباً $userName',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'ما هي خدمة الشحن التي تريدها اليوم؟',
                      style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ServiceTypeCard(
                            serviceType: ServiceType.internationalRoad,
                            icon: Icons.local_shipping,
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.createShipment,
                              arguments: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ServiceTypeCard(
                            serviceType: ServiceType.maritime,
                            icon: Icons.directions_boat,
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.createShipment,
                              arguments: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ServiceTypeCard(
                            serviceType: ServiceType.domestic,
                            icon: Icons.local_shipping,
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.createShipment,
                              arguments: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        _QuickActionCard(
                          icon: Icons.search,
                          label: 'تتبع شحنة',
                          color: AppTheme.secondaryTeal,
                          onTap: () {
                            final controller = TextEditingController();
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('تتبع شحنة'),
                                content: TextField(
                                  controller: controller,
                                  textDirection: TextDirection.rtl,
                                  decoration: const InputDecoration(
                                    labelText: 'رقم التتبع',
                                    hintText: 'أدخل رقم التتبع',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('إلغاء'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      if (controller.text.isNotEmpty) {
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.tracking,
                                          arguments: controller.text,
                                        );
                                      }
                                    },
                                    child: const Text('تتبع'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        _QuickActionCard(
                          icon: Icons.add_circle_outline,
                          label: 'إنشاء شحنة',
                          color: AppTheme.primaryBlue,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.createShipment,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _QuickActionCard(
                          icon: Icons.calculate_outlined,
                          label: 'حاسبة السعر',
                          color: AppTheme.accentGreen,
                          onTap: () =>
                              Navigator.pushNamed(context, AppRoutes.pricing),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'آخر الشحنات',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRoutes.shipments),
                          child: const Text('عرض الكل'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (shipmentProv.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (shipmentProv.shipments.isEmpty)
                      _buildEmptyShipments()
                    else
                      ...shipmentProv.shipments
                          .take(5)
                          .map(
                            (s) => ShipmentCard(
                              shipment: s,
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.shipmentDetail,
                                arguments: s.id,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyShipments() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: const Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: Color(0xFF94A3B8)),
          SizedBox(height: 12),
          Text(
            'لا توجد شحنات حالياً',
            style: TextStyle(fontSize: 16, color: Color(0xFF94A3B8)),
          ),
          SizedBox(height: 4),
          Text(
            'قم بإنشاء شحنتك الأولى الآن',
            style: TextStyle(fontSize: 13, color: Color(0xFFCBD5E1)),
          ),
        ],
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
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
