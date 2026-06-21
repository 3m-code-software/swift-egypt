import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swift_egypt_shared/swift_egypt_shared.dart';
import '../../core/theme.dart';
import '../../core/routes.dart';
import '../../providers/shipment_provider.dart';

class PricingCalculatorScreen extends StatefulWidget {
  const PricingCalculatorScreen({super.key});

  @override
  State<PricingCalculatorScreen> createState() => _PricingCalculatorScreenState();
}

class _PricingCalculatorScreenState extends State<PricingCalculatorScreen> {
  int _selectedService = 0;
  final _weightCtrl = TextEditingController();
  final _lengthCtrl = TextEditingController();
  final _widthCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  bool _insurance = false;
  bool _express = false;
  bool _packaging = false;
  Map<String, dynamic>? _result;
  bool _calculating = false;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _lengthCtrl.dispose();
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  Future<void> _calculate() async {
    if (_weightCtrl.text.isEmpty) return;
    setState(() => _calculating = true);
    final prov = context.read<ShipmentProvider>();
    final data = {
      'service_type': ServiceType.values[_selectedService].apiValue,
      'weight': double.tryParse(_weightCtrl.text) ?? 0,
      'length': double.tryParse(_lengthCtrl.text),
      'width': double.tryParse(_widthCtrl.text),
      'height': double.tryParse(_heightCtrl.text),
      'insurance': _insurance,
      'express': _express,
      'packaging': _packaging,
    };
    final result = await prov.estimatePrice(data);
    setState(() {
      _result = result;
      _calculating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حاسبة السعر')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('نوع الخدمة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _selectedService,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.category_outlined)),
              items: [
                DropdownMenuItem(value: 0, child: const Text('شحن دولي بري')),
                DropdownMenuItem(value: 1, child: const Text('شحن بحري')),
                DropdownMenuItem(value: 2, child: const Text('شحن داخلي')),
              ],
              onChanged: (v) => setState(() => _selectedService = v!),
            ),
            const SizedBox(height: 20),
            const Text('وزن وأبعاد الشحنة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _weightCtrl,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(labelText: 'الوزن (كجم)', prefixIcon: Icon(Icons.monitor_weight_outlined)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: _lengthCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الطول (سم)'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _widthCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'العرض (سم)'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _heightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الارتفاع (سم)'))),
              ],
            ),
            const SizedBox(height: 20),
            const Text('خدمات إضافية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            CheckboxListTile(title: const Text('تأمين'), value: _insurance, onChanged: (v) => setState(() => _insurance = v!), controlAffinity: ListTileControlAffinity.leading),
            CheckboxListTile(title: const Text('شحن سريع (Express)'), value: _express, onChanged: (v) => setState(() => _express = v!), controlAffinity: ListTileControlAffinity.leading),
            CheckboxListTile(title: const Text('تغليف احترافي'), value: _packaging, onChanged: (v) => setState(() => _packaging = v!), controlAffinity: ListTileControlAffinity.leading),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _calculating ? null : _calculate,
                icon: _calculating
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                    : const Icon(Icons.calculate),
                label: Text(_calculating ? 'جاري الحساب...' : 'احسب السعر'),
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text('تفاصيل السعر', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      if (_result!['base_price'] != null) _buildRow('السعر الأساسي', _result!['base_price']),
                      if (_result!['weight_price'] != null) _buildRow('سعر الوزن', _result!['weight_price']),
                      if (_result!['volume_price'] != null) _buildRow('سعر الحجم', _result!['volume_price']),
                      if (_result!['insurance'] != null) _buildRow('التأمين', _result!['insurance']),
                      if (_result!['express'] != null) _buildRow('الشحن السريع', _result!['express']),
                      if (_result!['packaging'] != null) _buildRow('التغليف', _result!['packaging']),
                      if (_result!['tax'] != null) _buildRow('الضريبة', _result!['tax']),
                      const Divider(thickness: 1),
                      _buildRow('الإجمالي', _result!['total'], bold: true, color: AppTheme.primaryBlue),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.createShipment),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('إنشاء شحنة'),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, dynamic value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 16 : 14)),
          Text('${(value as num).toStringAsFixed(2)} ج.م',
              style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 16 : 14, color: color)),
        ],
      ),
    );
  }
}
