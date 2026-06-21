import 'package:flutter/material.dart';
import 'package:swift_egypt_shared/swift_egypt_shared.dart';
import '../../core/theme.dart';

class StatusUpdateScreen extends StatefulWidget {
  final BatchOrder order;
  final String initialStatus;

  const StatusUpdateScreen({
    super.key,
    required this.order,
    required this.initialStatus,
  });

  @override
  State<StatusUpdateScreen> createState() => _StatusUpdateScreenState();
}

class _StatusUpdateScreenState extends State<StatusUpdateScreen> {
  late String _selectedStatus;
  final _notesController = TextEditingController();
  String? _selectedReturnReason;
  final _collectedController = TextEditingController();
  final _deliveredQtyController = TextEditingController();
  bool _isSubmitting = false;

  final _returnReasons = [
    {'key': 'customer_refused', 'label': 'العميل رفض الاستلام'},
    {'key': 'wrong_address', 'label': 'عنوان خطأ'},
    {'key': 'customer_not_found', 'label': 'العميل غير موجود'},
    {'key': 'cancelled_by_seller', 'label': 'ملغي من التاجر'},
    {'key': 'damaged_product', 'label': 'منتج تالف'},
    {'key': 'wrong_product', 'label': 'منتج خطأ'},
    {'key': 'delayed_delivery', 'label': 'تأخر التوصيل'},
    {'key': 'other', 'label': 'سبب آخر'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus;
    _deliveredQtyController.text = widget.order.quantity.toString();
    if (widget.initialStatus == 'returned') {
      _selectedReturnReason = _returnReasons.first['key'];
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _collectedController.dispose();
    _deliveredQtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_getTitle())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusSelector(),
            const SizedBox(height: 16),
            if (_selectedStatus == 'returned') _buildReturnReasonSection(),
            if (_selectedStatus == 'partial') _buildDeliveredQtySection(),
            if (_selectedStatus == 'delivered' || _selectedStatus == 'partial')
              _buildCollectionSection(),
            const SizedBox(height: 16),
            _buildNotesSection(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _getStatusColor(),
                minimumSize: const Size(double.infinity, 52),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(_getButtonText(),
                      style: const TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSelector() {
    final statuses = [
      {'key': 'delivered', 'label': 'تم التوصيل', 'icon': Icons.check_circle_rounded, 'color': AppTheme.accentGreen},
      {'key': 'partial', 'label': 'توصيل جزئي', 'icon': Icons.remove_circle_outline_rounded, 'color': AppTheme.warningOrange},
      {'key': 'returned', 'label': 'مرتجع', 'icon': Icons.replay_rounded, 'color': AppTheme.errorRed},
      {'key': 'no_answer', 'label': 'لا رد', 'icon': Icons.phone_missed_rounded, 'color': Colors.grey},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('حالة التوصيل', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...statuses.map((s) => RadioListTile<String>(
                  value: s['key'] as String,
                  groupValue: _selectedStatus,
                  title: Row(
                    children: [
                      Icon(s['icon'] as IconData, color: s['color'] as Color, size: 20),
                      const SizedBox(width: 8),
                      Text(s['label'] as String),
                    ],
                  ),
                  onChanged: (v) => setState(() {
                    _selectedStatus = v!;
                    if (v == 'returned' && _selectedReturnReason == null) {
                      _selectedReturnReason = _returnReasons.first['key'];
                    }
                    if (v == 'partial') {
                      _deliveredQtyController.text = widget.order.quantity.toString();
                    }
                  }),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnReasonSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('سبب الإرجاع', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ..._returnReasons.map((r) => RadioListTile<String>(
                  value: r['key'] as String,
                  groupValue: _selectedReturnReason,
                  title: Text(r['label'] as String),
                  dense: true,
                  onChanged: (v) => setState(() => _selectedReturnReason = v),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveredQtySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الكمية المسلمة', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              controller: _deliveredQtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'عدد القطع المسلمة',
                prefixIcon: Icon(Icons.inventory_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('التحصيل', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              controller: _collectedController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'المبلغ المحصل',
                prefixIcon: const Icon(Icons.money_rounded),
                hintText: '${widget.order.total.toStringAsFixed(2)} ج.م',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ملاحظات', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'ملاحظات التوصيل (اختياري)',
                prefixIcon: Icon(Icons.notes_rounded),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final result = <String, dynamic>{
      'status': _selectedStatus,
      'delivery_notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      'returned_reason':
          _selectedStatus == 'returned' ? _selectedReturnReason : null,
      'collected_amount': _collectedController.text.trim().isEmpty
          ? (_selectedStatus == 'delivered' ? widget.order.total : null)
          : double.tryParse(_collectedController.text.trim()),
      'delivered_quantity': _selectedStatus == 'partial'
          ? int.tryParse(_deliveredQtyController.text.trim())
          : null,
    };

    Navigator.of(context).pop(result);
  }

  String _getTitle() {
    switch (_selectedStatus) {
      case 'delivered': return 'تأكيد التوصيل';
      case 'partial': return 'توصيل جزئي';
      case 'returned': return 'إرجاع الطلب';
      case 'no_answer': return 'لا رد';
      default: return 'تحديث الحالة';
    }
  }

  String _getButtonText() {
    switch (_selectedStatus) {
      case 'delivered': return 'تأكيد التوصيل';
      case 'partial': return 'تأكيد التوصيل الجزئي';
      case 'returned': return 'تأكيد الإرجاع';
      case 'no_answer': return 'تأكيد لا رد';
      default: return 'تأكيد';
    }
  }

  Color _getStatusColor() {
    switch (_selectedStatus) {
      case 'delivered': return AppTheme.accentGreen;
      case 'partial': return AppTheme.warningOrange;
      case 'returned': return AppTheme.errorRed;
      case 'no_answer': return Colors.grey;
      default: return AppTheme.primaryBlue;
    }
  }
}
