import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';
import 'payment_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String? invoiceId;
  final double amount;

  const PaymentScreen({
    super.key,
    this.invoiceId,
    required this.amount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  bool _isLoading = false;
  final _api = ApiService();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await _api.post('/payments/confirm', body: {
        if (widget.invoiceId != null) 'invoice_id': widget.invoiceId,
        'amount': widget.amount,
        'payment_method': 'credit_card',
        'card_last_four': _cardNumberController.text.trim().substring(
          _cardNumberController.text.trim().length - 4,
        ),
        'card_holder_name': _cardHolderController.text.trim(),
      });

      if (!mounted) return;

      final transactionId = response['transaction_id'] as String? ??
          response['transactionId'] as String? ??
          '';

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PaymentSuccessScreen(
            transactionId: transactionId,
            amount: widget.amount,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().contains('message')
              ? 'فشلت عملية الدفع. حاول مرة أخرى.'
              : 'فشلت عملية الدفع. حاول مرة أخرى.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدفع')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 24),
              Text(
                '${widget.amount.toStringAsFixed(2)} جنيه',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'المبلغ المستحق',
                style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'بيانات البطاقة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _cardNumberController,
                        keyboardType: TextInputType.number,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.left,
                        maxLength: 16,
                        decoration: const InputDecoration(
                          labelText: 'رقم البطاقة',
                          prefixIcon: Icon(Icons.credit_card),
                          counterText: '',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().length != 16) {
                            return 'يجب إدخال 16 رقماً';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _cardHolderController,
                        textDirection: TextDirection.rtl,
                        decoration: const InputDecoration(
                          labelText: 'اسم حامل البطاقة',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'هذا الحقل مطلوب';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _expiryController,
                              keyboardType: TextInputType.datetime,
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.left,
                              decoration: const InputDecoration(
                                labelText: 'تاريخ الانتهاء',
                                hintText: 'MM/YY',
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().length < 5) {
                                  return 'صيغة غير صحيحة';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _cvvController,
                              keyboardType: TextInputType.number,
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.left,
                              maxLength: 3,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'CVV',
                                prefixIcon: Icon(Icons.lock),
                                counterText: '',
                              ),
                              validator: (v) {
                                if (v == null || v.trim().length != 3) {
                                  return '3 أرقام مطلوبة';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _pay,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('ادفع الآن'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
