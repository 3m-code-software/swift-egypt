import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swift_egypt_shared/swift_egypt_shared.dart';
import '../../core/theme.dart';
import '../../core/routes.dart';
import '../../providers/shipment_provider.dart';
import '../../widgets/shipment_card.dart';
import '../../widgets/empty_state.dart';

class ShipmentListScreen extends StatefulWidget {
  const ShipmentListScreen({super.key});

  @override
  State<ShipmentListScreen> createState() => _ShipmentListScreenState();
}

class _ShipmentListScreenState extends State<ShipmentListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShipmentProvider>().loadShipments();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ShipmentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('الشحنات'),
        actions: [
          IconButton(
            icon: Icon(
              prov.showAdvancedFilters
                  ? Icons.filter_list_off
                  : Icons.filter_list,
            ),
            onPressed: prov.toggleAdvancedFilters,
            tooltip: 'فلاتر متقدمة',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'ترتيب',
            onSelected: prov.setSortBy,
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'newest',
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward, size: 18),
                    SizedBox(width: 8),
                    Text('الأحدث أولاً'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'oldest',
                child: Row(
                  children: [
                    Icon(Icons.arrow_upward, size: 18),
                    SizedBox(width: 8),
                    Text('الأقدم أولاً'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'بحث بالرقم أو الاسم أو العنوان',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          prov.setSearchQuery('');
                        },
                      )
                    : null,
              ),
              onChanged: prov.setSearchQuery,
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _filterChip('الكل', null, prov.filterStatus),
                _filterChip('نشط', 'active', prov.filterStatus),
                _filterChip('قيد الشحن', 'in_transit', prov.filterStatus),
                _filterChip('تم التسليم', 'delivered', prov.filterStatus),
                _filterChip('ملغي', 'cancelled', prov.filterStatus),
              ],
            ),
          ),
          if (prov.showAdvancedFilters) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _serviceFilterChip('الكل الخدمات', null, prov.filterServiceType),
                  _serviceFilterChip(
                    'دولي برّي',
                    ServiceType.internationalRoad.name,
                    prov.filterServiceType,
                  ),
                  _serviceFilterChip(
                    'بحري',
                    ServiceType.maritime.name,
                    prov.filterServiceType,
                  ),
                  _serviceFilterChip(
                    'محلي',
                    ServiceType.domestic.name,
                    prov.filterServiceType,
                  ),
                ],
              ),
            ),
          ],
          if (_hasActiveFilters(prov))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.filter_alt, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'مرشح: ${_getActiveFilterCount(prov)} فلتر',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      _searchCtrl.clear();
                      prov.clearAllFilters();
                    },
                    child: const Text('مسح الكل', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => prov.loadShipments(),
              child: prov.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : prov.shipments.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 80),
                            EmptyState(
                              icon: Icons.inventory_2_outlined,
                              title: 'لا توجد شحنات',
                              subtitle: 'لم تقم بإنشاء أي شحنات بعد',
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: prov.shipments.length,
                          itemBuilder: (_, i) => ShipmentCard(
                            shipment: prov.shipments[i],
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.shipmentDetail,
                              arguments: prov.shipments[i].id,
                            ),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters(ShipmentProvider prov) {
    return prov.filterStatus != null ||
        prov.filterServiceType != null ||
        prov.searchQuery.isNotEmpty;
  }

  int _getActiveFilterCount(ShipmentProvider prov) {
    int count = 0;
    if (prov.filterStatus != null) count++;
    if (prov.filterServiceType != null) count++;
    if (prov.searchQuery.isNotEmpty) count++;
    return count;
  }

  Widget _filterChip(String label, String? value, String? current) {
    final isSelected = current == value || (value == null && current == null);
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => context.read<ShipmentProvider>().setFilter(value),
      ),
    );
  }

  Widget _serviceFilterChip(String label, String? value, String? current) {
    final isSelected = current == value || (value == null && current == null);
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        avatar: value != null
            ? Icon(
                value == ServiceType.internationalRoad.name
                    ? Icons.local_shipping
                    : value == ServiceType.maritime.name
                        ? Icons.directions_boat
                        : Icons.local_shipping,
                size: 16,
              )
            : null,
        label: Text(label),
        selected: isSelected,
        onSelected: (_) =>
            context.read<ShipmentProvider>().setServiceTypeFilter(value),
      ),
    );
  }
}
