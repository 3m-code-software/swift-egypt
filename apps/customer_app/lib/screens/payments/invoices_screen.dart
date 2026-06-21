import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swift_egypt_shared/swift_egypt_shared.dart';
import '../../core/theme.dart';
import '../../providers/shipment_provider.dart';
import '../../widgets/empty_state.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShipmentProvider>().loadInvoices();
    });
  }

  List<Invoice> _filtered(List<Invoice> invoices) {
    if (_statusFilter == null) return invoices;
    return invoices.where((inv) => inv.paymentStatus.apiValue == _statusFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ShipmentProvider>();
    final invoices = _filtered(prov.invoices);

    return Scaffold(
      appBar: AppBar(title: const Text('الفواتير')),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _chip('الكل', null),
                _chip('قيد الانتظار', 'pending'),
                _chip('مدفوع', 'paid'),
                _chip('متأخر', 'overdue'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: prov.isLoading
                ? const Center(child: CircularProgressIndicator())
                : invoices.isEmpty
                    ? const EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'لا توجد فواتير',
                        subtitle: 'ستظهر الفواتير هنا بعد إنشاء الشحنات',
                      )
                    : RefreshIndicator(
                        onRefresh: () => prov.loadInvoices(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: invoices.length,
                          itemBuilder: (_, i) {
                            final inv = invoices[i];
                            final statusColor = inv.paymentStatus == PaymentStatus.paid
                                ? AppTheme.accentGreen
                                : inv.paymentStatus == PaymentStatus.pending
                                    ? AppTheme.warningAmber
                                    : AppTheme.errorRed;
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(inv.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(inv.paymentStatus.displayName,
                                              style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('${inv.createdAt.toString().substring(0, 10)}', style: const TextStyle(color: Color(0xFF64748B))),
                                        Text('${inv.total.toStringAsFixed(2)} ج.م',
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                                      ],
                                    ),
                                    if (inv.paymentStatus != PaymentStatus.paid) ...[
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          onPressed: () {},
                                          icon: const Icon(Icons.payment, size: 18),
                                          label: const Text('دفع'),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String? value) {
    final sel = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(label: Text(label), selected: sel, onSelected: (_) => setState(() => _statusFilter = value)),
    );
  }
}
