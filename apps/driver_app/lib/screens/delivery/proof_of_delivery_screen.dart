import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme.dart';
import '../../providers/task_provider.dart';
import '../../services/location_service.dart';
import '../../widgets/signature_dialog.dart';

class ProofOfDeliveryScreen extends StatefulWidget {
  final String shipmentId;

  const ProofOfDeliveryScreen({super.key, required this.shipmentId});

  @override
  State<ProofOfDeliveryScreen> createState() => _ProofOfDeliveryScreenState();
}

class _ProofOfDeliveryScreenState extends State<ProofOfDeliveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recipientController = TextEditingController();
  final _notesController = TextEditingController();
  final _picker = ImagePicker();

  String? _photoPath;
  String? _signaturePath;
  double? _latitude;
  double? _longitude;
  bool _isSubmitting = false;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _captureLocation();
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _captureLocation() async {
    final position = await LocationService.getCurrentPosition();
    if (position != null && mounted) {
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    }
  }

  Future<void> _takePhoto() async {
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (photo != null) {
        setState(() => _photoPath = photo.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ في التقاط الصورة')),
        );
      }
    }
  }

  Future<void> _captureSignature() async {
    final Uint8List? pngBytes = await showDialog<Uint8List>(
      context: context,
      builder: (_) => const SignatureDialog(),
    );
    if (pngBytes != null && mounted) {
      final dir = Directory.systemTemp;
      final file = File('${dir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);
      setState(() => _signaturePath = file.path);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final provider = context.read<TaskProvider>();
    final success = await provider.submitProofOfDelivery(
      shipmentId: widget.shipmentId,
      recipientName: _recipientController.text.trim(),
      photoPath: _photoPath,
      signaturePath: _signaturePath,
      latitude: _latitude,
      longitude: _longitude,
      notes: _notesController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _showSuccess = success;
      });

      if (success) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'حدث خطأ في إرسال إثبات التسليم'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSuccess) {
      return _buildSuccessScreen();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('إثبات التسليم')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPhotoSection(),
              const SizedBox(height: 16),
              _buildSignatureSection(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _recipientController,
                decoration: const InputDecoration(
                  labelText: 'اسم المستلم',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'يرجى إدخال اسم المستلم';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات (اختياري)',
                  prefixIcon: Icon(Icons.notes_rounded),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              _buildLocationInfo(),
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
                    : const Text('تأكيد التسليم'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('صورة التسليم',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _takePhoto,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  image: _photoPath != null
                      ? DecorationImage(
                          image: FileImage(File(_photoPath!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _photoPath == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_rounded,
                              size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('اضغط لالتقاط صورة',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      )
                    : null,
              ),
            ),
            if (_photoPath != null)
              TextButton.icon(
                onPressed: () => setState(() => _photoPath = null),
                icon: const Icon(Icons.delete_rounded, color: AppTheme.errorRed),
                label: const Text('إزالة الصورة',
                    style: TextStyle(color: AppTheme.errorRed)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignatureSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('توقيع المستلم',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _captureSignature,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _signaturePath == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.draw_rounded,
                              size: 36, color: Colors.grey),
                          SizedBox(height: 4),
                          Text('اضغط للتوقيع',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      )
                    : const Icon(Icons.check_circle_rounded,
                        size: 48, color: AppTheme.accentGreen),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.gps_fixed_rounded,
                color: AppTheme.primaryBlue, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الموقع الجغرافي',
                      style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    _latitude != null
                        ? '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}'
                        : 'جاري تحديد الموقع...',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('إثبات التسليم')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded,
                size: 100, color: AppTheme.accentGreen),
            const SizedBox(height: 24),
            const Text(
              'تم تسليم الشحنة بنجاح!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'تم حفظ إثبات التسليم',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
