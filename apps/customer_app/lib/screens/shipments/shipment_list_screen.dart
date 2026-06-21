import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      appBar: AppBar(title: const Text('الشحنات')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'بحث برقم التتبع',
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
                _filterChip('تم التسليم', 'delivered', prov.filterStatus),
                _filterChip('ملغي', 'cancelled', prov.filterStatus),
              ],
            ),
          ),
          const SizedBox(height: 8),
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
}
