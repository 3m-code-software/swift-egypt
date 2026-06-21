import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/routes.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final String transactionId;
  final double amount;

  const PaymentSuccessScreen({
    super.key,
    required this.transactionId,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.accentGreen,
                  size: 80,
                ),
                const SizedBox(height: 24),
                const Text(
                  'تم الدفع بنجاح',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _detailRow(
                          'رقم العملية',
                          transactionId,
                        ),
                        const Divider(height: 24),
                        _detailRow(
                          'المبلغ',
                          '${amount.toStringAsFixed(2)} ج.م',
                        ),
                        const Divider(height: 24),
                        _detailRow(
                          'التاريخ',
                          dateStr,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'شكراً لاستخدامك Swift Egypt',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.local_shipping,
                    size: 44,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context)
                        .pushNamedAndRemoveUntil(
                            AppRoutes.home, (_) => false),
                    child: const Text('العودة إلى الرئيسية'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
