import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swift_egypt_shared/swift_egypt_shared.dart';
import '../../core/theme.dart';
import '../../core/routes.dart';
import '../../providers/shipment_provider.dart';

class CreateShipmentScreen extends StatefulWidget {
  final int? serviceType;
  const CreateShipmentScreen({super.key, this.serviceType});

  @override
  State<CreateShipmentScreen> createState() => _CreateShipmentScreenState();
}

class _CreateShipmentScreenState extends State<CreateShipmentScreen> {
  int _currentStep = 0;
  int _selectedService = 0;
  final _senderNameCtrl = TextEditingController();
  final _senderPhoneCtrl = TextEditingController();
  final _pickupAddressCtrl = TextEditingController();
  final _recipientNameCtrl = TextEditingController();
  final _recipientPhoneCtrl = TextEditingController();
  final _deliveryAddressCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController(text: '1');
  final _weightCtrl = TextEditingController();
  final _lengthCtrl = TextEditingController();
  final _widthCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  Map<String, dynamic>? _priceEstimate;
  bool _calculating = false;

  @override
  void initState() {
    super.initState();
    if (widget.serviceType != null) {
      _selectedService = widget.serviceType!;
    }
  }

  @override
  void dispose() {
    _senderNameCtrl.dispose();
    _senderPhoneCtrl.dispose();
    _pickupAddressCtrl.dispose();
    _recipientNameCtrl.dispose();
    _recipientPhoneCtrl.dispose();
    _deliveryAddressCtrl.dispose();
    _descriptionCtrl.dispose();
    _quantityCtrl.dispose();
    _weightCtrl.dispose();
    _lengthCtrl.dispose();
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  Future<void> _estimatePrice() async {
    if (_weightCtrl.text.isEmpty) return;
    setState(() => _calculating = true);
    final prov = context.read<ShipmentProvider>();
    final result = await prov.estimatePrice({
      'service_type': ServiceType.values[_selectedService].apiValue,
      'weight': double.tryParse(_weightCtrl.text) ?? 0,
      'length': double.tryParse(_lengthCtrl.text),
      'width': double.tryParse(_widthCtrl.text),
      'height': double.tryParse(_heightCtrl.text),
    });
    setState(() {
      _priceEstimate = result;
      _calculating = false;
    });
  }

  Future<void> _submit() async {
    final prov = context.read<ShipmentProvider>();
    final items = [
      {
        'description': _descriptionCtrl.text,
        'quantity': int.tryParse(_quantityCtrl.text) ?? 1,
        'weight': double.tryParse(_weightCtrl.text) ?? 0,
        'length': double.tryParse(_lengthCtrl.text),
        'width': double.tryParse(_widthCtrl.text),
        'height': double.tryParse(_heightCtrl.text),
      },
    ];
    final data = {
      'service_type': ServiceType.values[_selectedService].apiValue,
      'sender_name': _senderNameCtrl.text,
      'sender_phone': _senderPhoneCtrl.text,
      'pickup_address': _pickupAddressCtrl.text,
      'recipient_name': _recipientNameCtrl.text,
      'recipient_phone': _recipientPhoneCtrl.text,
      'delivery_address': _deliveryAddressCtrl.text,
      'items': items,
    };
    final tracking = await prov.createShipment(data);
    if (tracking != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('تم إنشاء الشحنة بنجاح'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: AppTheme.accentGreen, size: 64),
              const SizedBox(height: 16),
              Text('رقم التتبع: $tracking', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('سيتم التواصل معك قريباً لتأكيد الشحنة'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacementNamed(context, AppRoutes.home);
              },
              child: const Text('العودة للرئيسية'),
            ),
          ],
        ),
      );
    }
  }

  bool _canProceed(int step) {
    switch (step) {
      case 1:
        return _senderNameCtrl.text.isNotEmpty && _pickupAddressCtrl.text.isNotEmpty;
      case 2:
        return _recipientNameCtrl.text.isNotEmpty && _deliveryAddressCtrl.text.isNotEmpty;
      case 3:
        return _descriptionCtrl.text.isNotEmpty && _weightCtrl.text.isNotEmpty;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = [
      {'name': 'شحن دولي بري', 'icon': Icons.local_shipping, 'desc': 'الشحن البري إلى الدول العربية والعالم'},
      {'name': 'شحن بحري', 'icon': Icons.directions_boat, 'desc': 'الشحن البحري للحاويات والبضائع'},
      {'name': 'شحن داخلي', 'icon': Icons.local_shipping, 'desc': 'الشحن داخل مصر'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء شحنة جديدة')),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 4) {
            if (_canProceed(_currentStep + 1)) {
              setState(() => _currentStep++);
            }
          } else {
            _submit();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) setState(() => _currentStep--);
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  child: Text(_currentStep == 4 ? 'تأكيد وإنشاء' : 'التالي'),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 12),
                  TextButton(onPressed: details.onStepCancel, child: const Text('السابق')),
                ],
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('نوع الخدمة'),
            content: Column(
              children: List.generate(services.length, (i) {
                final s = services[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: RadioListTile<int>(
                    title: Text(s['name'] as String),
                    subtitle: Text(s['desc'] as String),
                    secondary: Icon(s['icon'] as IconData, color: AppTheme.primaryBlue),
                    value: i,
                    groupValue: _selectedService,
                    onChanged: (v) => setState(() => _selectedService = v!),
                  ),
                );
              }),
            ),
            isActive: _currentStep >= 0,
          ),
          Step(
            title: const Text('معلومات المرسل'),
            content: Column(
              children: [
                TextField(controller: _senderNameCtrl, textDirection: TextDirection.rtl, decoration: const InputDecoration(labelText: 'اسم المرسل')),
                const SizedBox(height: 12),
                TextField(controller: _senderPhoneCtrl, textDirection: TextDirection.rtl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف')),
                const SizedBox(height: 12),
                TextField(controller: _pickupAddressCtrl, textDirection: TextDirection.rtl, maxLines: 2, decoration: const InputDecoration(labelText: 'عنوان الاستلام', prefixIcon: Icon(Icons.location_on_outlined))),
              ],
            ),
            isActive: _currentStep >= 1,
          ),
          Step(
            title: const Text('معلومات المستلم'),
            content: Column(
              children: [
                TextField(controller: _recipientNameCtrl, textDirection: TextDirection.rtl, decoration: const InputDecoration(labelText: 'اسم المستلم')),
                const SizedBox(height: 12),
                TextField(controller: _recipientPhoneCtrl, textDirection: TextDirection.rtl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف')),
                const SizedBox(height: 12),
                TextField(controller: _deliveryAddressCtrl, textDirection: TextDirection.rtl, maxLines: 2, decoration: const InputDecoration(labelText: 'عنوان التسليم', prefixIcon: Icon(Icons.location_on_outlined))),
              ],
            ),
            isActive: _currentStep >= 2,
          ),
          Step(
            title: const Text('تفاصيل الشحنة'),
            content: Column(
              children: [
                TextField(controller: _descriptionCtrl, textDirection: TextDirection.rtl, maxLines: 2, decoration: const InputDecoration(labelText: 'وصف الشحنة')),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _quantityCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'العدد'))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: _weightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الوزن (كجم)'))),
                  ],
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
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _calculating ? null : _estimatePrice,
                  icon: _calculating
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.calculate),
                  label: const Text('احسب السعر'),
                ),
                if (_priceEstimate != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (_priceEstimate!['base_price'] != null)
                            _priceRow('السعر الأساسي', _priceEstimate!['base_price']),
                          if (_priceEstimate!['weight_price'] != null)
                            _priceRow('سعر الوزن', _priceEstimate!['weight_price']),
                          if (_priceEstimate!['volume_price'] != null)
                            _priceRow('سعر الحجم', _priceEstimate!['volume_price']),
                          if (_priceEstimate!['insurance'] != null)
                            _priceRow('التأمين', _priceEstimate!['insurance']),
                          if (_priceEstimate!['tax'] != null)
                            _priceRow('الضريبة', _priceEstimate!['tax']),
                          const Divider(),
                          _priceRow('الإجمالي', _priceEstimate!['total'], bold: true),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            isActive: _currentStep >= 3,
          ),
          Step(
            title: const Text('مراجعة وتأكيد'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _reviewSection('نوع الخدمة', services[_selectedService]['name'] as String),
                _reviewSection('المرسل', '${_senderNameCtrl.text} - ${_senderPhoneCtrl.text}'),
                _reviewSection('عنوان الاستلام', _pickupAddressCtrl.text),
                _reviewSection('المستلم', '${_recipientNameCtrl.text} - ${_recipientPhoneCtrl.text}'),
                _reviewSection('عنوان التسليم', _deliveryAddressCtrl.text),
                _reviewSection('الوصف', _descriptionCtrl.text),
                _reviewSection('الكمية', '${_quantityCtrl.text} قطعة - ${_weightCtrl.text} كجم'),
              ],
            ),
            isActive: _currentStep >= 4,
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, dynamic value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text('${(value as num).toStringAsFixed(2)} ج.م', style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: bold ? AppTheme.primaryBlue : null)),
        ],
      ),
    );
  }

  Widget _reviewSection(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}
