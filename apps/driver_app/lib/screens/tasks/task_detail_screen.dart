import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swift_egypt_shared/swift_egypt_shared.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../providers/task_provider.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/loading_overlay.dart';
import 'package:url_launcher/url_launcher.dart';
import '../delivery/status_update_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final String orderId;

  const TaskDetailScreen({super.key, required this.orderId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTaskDetail(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final order = taskProvider.selectedTask;

    return Scaffold(
      appBar: AppBar(
        title: Text(order?.customerName ?? 'تفاصيل الطلب'),
      ),
      body: taskProvider.isLoading
          ? const LoadingOverlay()
          : order == null
              ? Center(
                  child: Text(
                    taskProvider.error ?? 'لا توجد بيانات',
                    style: const TextStyle(color: AppTheme.errorRed),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(order),
                      const SizedBox(height: 16),
                      _buildCustomerCard(order),
                      const SizedBox(height: 12),
                      _buildAddressCard(order),
                      const SizedBox(height: 12),
                      _buildProductCard(order),
                      const SizedBox(height: 12),
                      _buildPriceCard(order),
                      const SizedBox(height: 12),
                      if (order.deliveryNotes != null ||
                          order.returnedReason != null)
                        _buildNotesCard(order),
                      const SizedBox(height: 16),
                      _buildActions(order),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader(BatchOrder order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الطلب', style: Theme.of(context).textTheme.bodyMedium),
                StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat('yyyy/MM/dd HH:mm').format(order.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (order.batchNumber != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.batch_prediction_rounded, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'دفعة: ${order.batchNumber}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(BatchOrder order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_rounded, color: AppTheme.primaryBlue, size: 20),
                const SizedBox(width: 8),
                Text('معلومات العميل', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Text('الاسم: ${order.customerName}',
                style: Theme.of(context).textTheme.bodyLarge),
            if (order.customerPhone != null) ...[
              const SizedBox(height: 4),
              InkWell(
                onTap: () => _makePhoneCall(order.customerPhone!),
                child: Row(
                  children: [
                    const Icon(Icons.phone_rounded, size: 14, color: AppTheme.primaryBlue),
                    const SizedBox(width: 4),
                    Text(order.customerPhone!,
                        style: const TextStyle(
                          color: AppTheme.primaryBlue,
                          decoration: TextDecoration.underline,
                        )),
                  ],
                ),
              ),
            ],
            if (order.customerPhone2 != null) ...[
              const SizedBox(height: 4),
              InkWell(
                onTap: () => _makePhoneCall(order.customerPhone2!),
                child: Row(
                  children: [
                    const Icon(Icons.phone_rounded, size: 14, color: AppTheme.primaryBlue),
                    const SizedBox(width: 4),
                    Text(order.customerPhone2!,
                        style: const TextStyle(
                          color: AppTheme.primaryBlue,
                          decoration: TextDecoration.underline,
                        )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(BatchOrder order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on_rounded, color: AppTheme.accentGreen, size: 20),
                const SizedBox(width: 8),
                Text('العنوان', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Text(order.address ?? '---',
                style: Theme.of(context).textTheme.bodyLarge),
            if (order.province != null || order.city != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  [order.city, order.province].where((x) => x != null).join(' - '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ),
            if (order.latitude != null && order.longitude != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${order.latitude!.toStringAsFixed(6)}, ${order.longitude!.toStringAsFixed(6)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BatchOrder order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.inventory_rounded, color: AppTheme.primaryBlue, size: 20),
                const SizedBox(width: 8),
                Text('المنتج', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(order.productName ?? '---',
                    style: Theme.of(context).textTheme.bodyLarge),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '× ${order.quantity}',
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (order.notes != null) ...[
              const SizedBox(height: 8),
              Text('ملاحظات: ${order.notes}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCard(BatchOrder order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _priceRow('سعر المنتج', '${order.productPrice.toStringAsFixed(2)} ج.م'),
            const Divider(height: 16),
            _priceRow('تكلفة الشحن', '${order.shippingCost.toStringAsFixed(2)} ج.م'),
            const Divider(height: 16),
            _priceRow('الإجمالي', '${order.total.toStringAsFixed(2)} ج.م',
                isTotal: true),
            if (order.collectedAmount != null) ...[
              const Divider(height: 16),
              _priceRow('المبلغ المحصل', '${order.collectedAmount!.toStringAsFixed(2)} ج.م',
                  isTotal: true, color: AppTheme.accentGreen),
            ],
          ],
        ),
      ),
    );
  }

  Widget _priceRow(String label, String value,
      {bool isTotal = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: isTotal
                ? Theme.of(context).textTheme.titleMedium
                : Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: color ?? (isTotal ? AppTheme.primaryBlue : Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesCard(BatchOrder order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notes_rounded, color: AppTheme.warningOrange, size: 20),
                const SizedBox(width: 8),
                Text('ملاحظات التوصيل', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            if (order.deliveryNotes != null) ...[
              const SizedBox(height: 8),
              Text(order.deliveryNotes!,
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
            if (order.returnedReason != null) ...[
              const SizedBox(height: 8),
              Text('سبب الإرجاع: ${_returnReasonLabel(order.returnedReason!)}',
                  style: const TextStyle(color: AppTheme.errorRed)),
            ],
            if (order.callAttempts != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('محاولات الاتصال: ${order.callAttempts}',
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            if (order.deliveredQuantity != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('الكمية المسلمة: ${order.deliveredQuantity} من ${order.quantity}',
                    style: Theme.of(context).textTheme.bodySmall),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BatchOrder order) {
    final status = order.status;
    List<Widget> buttons = [];

    if (status == OrderStatus.pending) {
      buttons.add(_actionButton(
        'بدء التوصيل',
        Icons.play_arrow_rounded,
        AppTheme.primaryBlue,
        () => _updateStatus(order.id, 'approved'),
      ));
    }

    if (status == OrderStatus.approved) {
      buttons.add(_actionButton(
        'تم التوصيل',
        Icons.check_circle_rounded,
        AppTheme.accentGreen,
        () => _navigateToStatusUpdate(order, 'delivered'),
      ));
      buttons.add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: OutlinedButton.icon(
          onPressed: () => _navigateToStatusUpdate(order, 'partial'),
          icon: const Icon(Icons.remove_circle_outline_rounded),
          label: const Text('توصيل جزئي'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.warningOrange,
            side: const BorderSide(color: AppTheme.warningOrange),
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
      ));
      buttons.add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: OutlinedButton.icon(
          onPressed: () => _navigateToStatusUpdate(order, 'returned'),
          icon: const Icon(Icons.replay_rounded),
          label: const Text('مرتجع'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.errorRed,
            side: const BorderSide(color: AppTheme.errorRed),
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
      ));
      buttons.add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: OutlinedButton.icon(
          onPressed: () => _updateStatus(order.id, 'no_answer'),
          icon: const Icon(Icons.phone_missed_rounded),
          label: const Text('لا رد'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey,
            side: const BorderSide(color: Colors.grey),
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
      ));
    }

    if (status == OrderStatus.delivered) {
      buttons.add(_successCard('تم التوصيل بنجاح', AppTheme.accentGreen));
    } else if (status == OrderStatus.partial) {
      buttons.add(_successCard('تم التوصيل جزئياً', AppTheme.warningOrange));
    } else if (status == OrderStatus.returned) {
      buttons.add(_successCard('مرتجع', AppTheme.errorRed));
    } else if (status == OrderStatus.noAnswer) {
      buttons.add(_successCard('لا رد', Colors.grey));
    }

    return Column(children: buttons);
  }

  Widget _successCard(String text, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: color, size: 24),
            const SizedBox(width: 12),
            Text(text,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(text),
        style: ElevatedButton.styleFrom(backgroundColor: color),
      ),
    );
  }

  Future<void> _updateStatus(String orderId, String status) async {
    final provider = context.read<TaskProvider>();
    final success = await provider.updateTaskStatus(
      orderId: orderId,
      status: status,
    );
    if (success && mounted) {
      provider.loadTaskDetail(orderId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحديث الحالة إلى ${_statusLabel(status)}')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'حدث خطأ'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  void _navigateToStatusUpdate(BatchOrder order, String defaultStatus) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => StatusUpdateScreen(
          order: order,
          initialStatus: defaultStatus,
        ),
      ),
    );

    if (result != null && mounted) {
      final provider = context.read<TaskProvider>();
      final success = await provider.updateTaskStatus(
        orderId: order.id,
        status: result['status'] as String,
        deliveryNotes: result['delivery_notes'] as String?,
        returnedReason: result['returned_reason'] as String?,
        collectedAmount: result['collected_amount'] as double?,
        deliveredQuantity: result['delivered_quantity'] as int?,
      );
      if (success && mounted) {
        provider.loadTaskDetail(order.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الحالة بنجاح')),
        );
      }
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'delivered': return 'تم التوصيل';
      case 'partial': return 'توصيل جزئي';
      case 'returned': return 'مرتجع';
      case 'no_answer': return 'لا رد';
      case 'approved': return 'قيد التوصيل';
      default: return status;
    }
  }

  String _returnReasonLabel(String reason) {
    switch (reason) {
      case 'customer_refused': return 'العميل رفض الاستلام';
      case 'wrong_address': return 'عنوان خطأ';
      case 'customer_not_found': return 'العميل غير موجود';
      case 'cancelled_by_seller': return 'ملغي من التاجر';
      case 'damaged_product': return 'منتج تالف';
      case 'wrong_product': return 'منتج خطأ';
      case 'delayed_delivery': return 'تأخر التوصيل';
      case 'end_of_day': return 'إنهاء اليوم';
      default: return reason;
    }
  }

  void _makePhoneCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('لا يمكن الاتصال بـ $phone')),
        );
      }
    }
  }
}


