import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/task_provider.dart';

class CollectionScreen extends StatefulWidget {
  final String shipmentId;
  final double amount;

  const CollectionScreen({
    super.key,
    required this.shipmentId,
    required this.amount,
  });

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  String _paymentMethod = 'cash';
  bool _isSubmitting = false;
  bool _showSuccess = false;

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    final provider = context.read<TaskProvider>();
    final success = await provider.submitCollection(
      shipmentId: widget.shipmentId,
      amount: widget.amount,
      paymentMethod: _paymentMethod,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _showSuccess = success;
      });

      if (success) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'حدث خطأ'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSuccess) {
      return Scaffold(
        appBar: AppBar(title: const Text('تحصيل')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded,
                  size: 100, color: AppTheme.accentGreen),
              const SizedBox(height: 24),
              const Text(
                'تم تأكيد التحصيل بنجاح!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentGreen,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('تحصيل المبلغ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long_rounded,
                        size: 48, color: AppTheme.primaryBlue),
                    const SizedBox(height: 12),
                    Text('المبلغ المطلوب تحصيله',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.amount.toStringAsFixed(2)} ج.م',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('طريقة الدفع',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildPaymentOption(
              'cash',
              Icons.money_rounded,
              'نقداً',
              'الدفع نقداً عند الاستلام',
            ),
            const SizedBox(height: 8),
            _buildPaymentOption(
              'card',
              Icons.credit_card_rounded,
              'بطاقة',
              'الدفع عن طريق بطاقة الائتمان',
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('تأكيد التحصيل'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.print_rounded),
              label: const Text('طباعة إيصال'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
      String value, IconData icon, String title, String subtitle) {
    final selected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: Card(
        color: selected
            ? AppTheme.primaryBlue.withValues(alpha: 0.05)
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? AppTheme.primaryBlue : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon,
                  color: selected ? AppTheme.primaryBlue : Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: selected
                                      ? AppTheme.primaryBlue
                                      : null,
                                )),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Radio<String>(
                value: value,
                groupValue: _paymentMethod,
                onChanged: (v) => setState(() => _paymentMethod = v!),
                activeColor: AppTheme.primaryBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
